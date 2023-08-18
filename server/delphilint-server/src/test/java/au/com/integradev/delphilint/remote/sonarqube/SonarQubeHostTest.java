package au.com.integradev.delphilint.remote.sonarqube;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import au.com.integradev.delphilint.remote.IssueStatus;
import au.com.integradev.delphilint.remote.RemoteActiveRule;
import au.com.integradev.delphilint.remote.RemoteIssue;
import au.com.integradev.delphilint.remote.RemotePlugin;
import au.com.integradev.delphilint.remote.RemoteRule;
import au.com.integradev.delphilint.remote.RuleSeverity;
import au.com.integradev.delphilint.remote.RuleType;
import au.com.integradev.delphilint.remote.SonarHostException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Collections;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import org.apache.commons.lang3.NotImplementedException;
import org.junit.jupiter.api.Test;

class SonarQubeHostTest {
  private static final Path RESOURCE_DIR =
      Path.of("src/test/resources/au/com/integradev/delphilint/remote/sonarqube/mockedApi");
  private static final String DEFAULT_QP_URL =
      "/api/qualityprofiles/search?language=delphi&defaults=true";
  private static final String QP_OK_JSON = "qualityProfileOk.json";
  private static final String QP_KEY = "AYmGl3ZO2-GgcVw1YiT1";

  private static SonarQubeHost buildSonarHost(SonarApi sonarApi) {
    return buildSonarHost(sonarApi, "");
  }

  private static SonarQubeHost buildSonarHost(SonarApi sonarApi, String projectKey) {
    return new SonarQubeHost(sonarApi, projectKey, "delphi", "communitydelphi", "delphi");
  }

  @Test
  void getsDefaultQualityProfileWhenNoProject() throws SonarHostException {
    var api = new ResourceBackedSonarApi(RESOURCE_DIR, Map.of(DEFAULT_QP_URL, QP_OK_JSON));

    var host = buildSonarHost(api);
    SonarQubeQualityProfile profile = host.getQualityProfile();

    assertEquals("AYmGl3ZO2-GgcVw1YiT1", QP_KEY);
    assertEquals("Sonar way", profile.getName());
    assertEquals("delphi", profile.getLanguage());
    assertEquals(89, profile.getActiveRuleCount());
  }

  @Test
  void getsQualityProfileByProjectKey() throws SonarHostException {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR,
            Map.of("/api/qualityprofiles/search?language=delphi&project=MyProject", QP_OK_JSON));

    var host = buildSonarHost(api, "MyProject");
    SonarQubeQualityProfile profile = host.getQualityProfile();

    assertEquals("AYmGl3ZO2-GgcVw1YiT1", profile.getKey());
    assertEquals("Sonar way", profile.getName());
    assertEquals("delphi", profile.getLanguage());
    assertEquals(89, profile.getActiveRuleCount());
  }

  @Test
  void throwsOnErrorQualityProfile() {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR,
            Map.of("/api/qualityprofiles/search?language=delphi&defaults=true", "error.json"));

    var host = buildSonarHost(api);
    assertThrows(SonarHostException.class, host::getQualityProfile);
  }

  @Test
  void getsRuleNamesByRuleKey() throws SonarHostException {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR,
            Map.of(
                DEFAULT_QP_URL,
                QP_OK_JSON,
                "/api/rules/search?ps=500&activation=true&f=name&language=delphi&qprofile="
                    + QP_KEY,
                "ruleNamesByRuleKeyOk.json"));

    var host = buildSonarHost(api);
    Map<String, String> ruleNamesByRuleKey = host.getRuleNamesByRuleKey();

    assertEquals(3, ruleNamesByRuleKey.size());
    assertEquals("name1", ruleNamesByRuleKey.get("key1"));
    assertEquals("name2", ruleNamesByRuleKey.get("key2"));
    assertEquals("name3", ruleNamesByRuleKey.get("key3"));
  }

  @Test
  void getsRules() throws SonarHostException {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR,
            Map.of(
                DEFAULT_QP_URL,
                QP_OK_JSON,
                "/api/rules/search?ps=500&activation=true&f=name,htmlDesc,severity&languages=delphi&qprofile="
                    + QP_KEY,
                "rulesOk.json"));

    var host = buildSonarHost(api);
    Set<RemoteRule> rules = host.getRules();

    assertEquals(3, rules.size());
  }

  @Test
  void parsesRule() throws SonarHostException {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR,
            Map.of(
                DEFAULT_QP_URL,
                QP_OK_JSON,
                "/api/rules/search?ps=500&activation=true&f=name,htmlDesc,severity&languages=delphi&qprofile="
                    + QP_KEY,
                "rulesSingularOk.json"));

    var host = buildSonarHost(api);
    Set<RemoteRule> rules = host.getRules();

    assertEquals(1, rules.size());
    RemoteRule rule = rules.stream().findFirst().orElse(null);
    assert rule != null;
    assertEquals("key1", rule.getKey());
    assertEquals("name1", rule.getName());
    assertEquals("html1", rule.getHtmlDesc());
    assertEquals(RuleSeverity.MAJOR, rule.getSeverity());
    assertEquals(RuleType.BUG, rule.getType());
  }

  @Test
  void getsNoResolvedIssuesWithNoProjectKey() {
    var api = new ResourceBackedSonarApi(RESOURCE_DIR, Collections.emptyMap());

    var host = buildSonarHost(api);
    assertTrue(host.getResolvedIssues(Set.of("UnitA.pas")).isEmpty());
  }

  @Test
  void getsResolvedIssuesAndHotspots() {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR,
            Map.of(
                DEFAULT_QP_URL,
                QP_OK_JSON,
                "/api/hotspots/search?files=UnitA.pas,&projectKey=MyProject&status=REVIEWED",
                "resolvedHotspotsOk.json",
                "/api/issues/search?componentKeys=MyProject:UnitA.pas,&resolved=true&resolutions=FALSE-POSITIVE,WONTFIX,FIXED",
                "resolvedIssuesOk.json",
                "/api/issues/search?componentKeys=MyProject:UnitA.pas,&resolved=true&resolutions=FALSE-POSITIVE,WONTFIX,FIXED&p=1",
                "resolvedIssuesOk.json"));

    var host = buildSonarHost(api, "MyProject");
    Set<RemoteIssue> resolvedIssues = new HashSet<>(host.getResolvedIssues(Set.of("UnitA.pas")));

    assertEquals(9, resolvedIssues.size());
  }

  @Test
  void getsUnresolvedIssuesAndHotspots() {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR,
            Map.of(
                DEFAULT_QP_URL,
                QP_OK_JSON,
                "/api/hotspots/search?files=UnitA.pas,&projectKey=MyProject",
                "unresolvedHotspotsOk.json",
                "/api/issues/search?componentKeys=MyProject:UnitA.pas,&resolved=false",
                "unresolvedIssuesOk.json",
                "/api/issues/search?componentKeys=MyProject:UnitA.pas,&resolved=false&p=1",
                "unresolvedIssuesOk.json"));

    var host = buildSonarHost(api, "MyProject");
    Set<RemoteIssue> unresolvedIssues =
        new HashSet<>(host.getUnresolvedIssues(Set.of("UnitA.pas")));

    assertEquals(8, unresolvedIssues.size());
  }

  @Test
  void doesNotTreatAcknowledgedHotspotsAsResolvedIssues() {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR,
            Map.of(
                DEFAULT_QP_URL,
                QP_OK_JSON,
                "/api/hotspots/search?files=UnitA.pas,&projectKey=MyProject&status=REVIEWED",
                "resolvedHotspotsOk.json",
                "/api/issues/search?componentKeys=MyProject:UnitA.pas,&resolved=true&resolutions=FALSE-POSITIVE,WONTFIX,FIXED",
                "resolvedIssuesOk.json",
                "/api/issues/search?componentKeys=MyProject:UnitA.pas,&resolved=true&resolutions=FALSE-POSITIVE,WONTFIX,FIXED&p=1",
                "resolvedIssuesOk.json"));

    var host = buildSonarHost(api, "MyProject");
    Set<RemoteIssue> resolvedIssues = new HashSet<>(host.getResolvedIssues(Set.of("UnitA.pas")));

    var reviewedHotspots =
        resolvedIssues.stream()
            .filter(issue -> issue.getStatus() == IssueStatus.REVIEWED)
            .collect(Collectors.toList());

    assertEquals(4, reviewedHotspots.size());
    assertTrue(
        reviewedHotspots.stream().noneMatch(issue -> "ACKNOWLEDGED".equals(issue.getResolution())));
  }

  @Test
  void treatsAcknowledgedHotspotsAsUnresolvedIssues() {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR,
            Map.of(
                DEFAULT_QP_URL,
                QP_OK_JSON,
                "/api/hotspots/search?files=UnitA.pas,&projectKey=MyProject",
                "unresolvedHotspotsOk.json",
                "/api/issues/search?componentKeys=MyProject:UnitA.pas,&resolved=false",
                "unresolvedIssuesOk.json",
                "/api/issues/search?componentKeys=MyProject:UnitA.pas,&resolved=false&p=1",
                "unresolvedIssuesOk.json"));

    var host = buildSonarHost(api, "MyProject");
    Set<RemoteIssue> unresolvedIssues =
        new HashSet<>(host.getUnresolvedIssues(Set.of("UnitA.pas")));

    var reviewedHotspots =
        unresolvedIssues.stream()
            .filter(issue -> issue.getStatus() == IssueStatus.REVIEWED)
            .collect(Collectors.toList());

    assertEquals(1, reviewedHotspots.size());
    assertEquals("ACKNOWLEDGED", reviewedHotspots.get(0).getResolution());
  }

  @Test
  void getsActiveRules() throws SonarHostException {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR,
            Map.of(
                DEFAULT_QP_URL,
                QP_OK_JSON,
                "/api/rules/search?ps=500&activation=true&f=actives,templateKey&language=delphi&qprofile="
                    + QP_KEY,
                "activeRulesOk.json"));

    var host = buildSonarHost(api);
    Set<RemoteActiveRule> activeRules = host.getActiveRules();

    assertEquals(3, activeRules.size());

    Set<String> expectedActiveRules =
        Set.of(
            "community-delphi:DestructorWithoutInherited",
            "community-delphi:TooManyParameters",
            "community-delphi:ClassName");
    assertEquals(
        expectedActiveRules,
        activeRules.stream().map(RemoteActiveRule::getRuleKey).collect(Collectors.toSet()));
  }

  @Test
  void getsActiveRulesWithParams() throws SonarHostException {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR,
            Map.of(
                DEFAULT_QP_URL,
                QP_OK_JSON,
                "/api/rules/search?ps=500&activation=true&f=actives,templateKey&language=delphi&qprofile="
                    + QP_KEY,
                "activeRulesOk.json"));

    var host = buildSonarHost(api);
    Set<RemoteActiveRule> activeRules = host.getActiveRules();

    assertEquals(3, activeRules.size());

    Optional<RemoteActiveRule> tooManyParams =
        activeRules.stream()
            .filter(filter -> "community-delphi:TooManyParameters".equals(filter.getRuleKey()))
            .findFirst();
    assertTrue(tooManyParams.isPresent());
    assertEquals(2, tooManyParams.get().getParams().size());
    assertEquals("5", tooManyParams.get().getParams().get("max"));
    assertEquals("7", tooManyParams.get().getParams().get("constructorMax"));
  }

  @Test
  void getsActiveRulesWithNoParams() throws SonarHostException {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR,
            Map.of(
                DEFAULT_QP_URL,
                QP_OK_JSON,
                "/api/rules/search?ps=500&activation=true&f=actives,templateKey&language=delphi&qprofile="
                    + QP_KEY,
                "activeRulesOk.json"));

    var host = buildSonarHost(api);
    Set<RemoteActiveRule> activeRules = host.getActiveRules();

    assertEquals(3, activeRules.size());

    Optional<RemoteActiveRule> tooManyParams =
        activeRules.stream()
            .filter(
                filter -> "community-delphi:DestructorWithoutInherited".equals(filter.getRuleKey()))
            .findFirst();
    assertTrue(tooManyParams.isPresent());
    assertEquals(0, tooManyParams.get().getParams().size());
  }

  @Test
  void getsPluginJar() throws SonarHostException {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR,
            Map.of("/api/plugins/download?plugin=abcd", "filepath1")); // Can be any file

    var host = buildSonarHost(api);
    Optional<Path> pluginJarPath = host.getPluginJar("abcd");
    assertTrue(pluginJarPath.isPresent());
  }

  @Test
  void getsOnlyDelphiPlugins() throws SonarHostException {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR, Map.of("/api/plugins/installed", "installedPluginsOk.json"));

    var host = buildSonarHost(api);
    Set<RemotePlugin> plugins = host.getDelphiPlugins();

    assertEquals(
        Set.of("communitydelphi", "mycustomdelphi"),
        plugins.stream().map(RemotePlugin::getPluginKey).collect(Collectors.toSet()));
  }

  @Test
  void getsDelphiPluginFilenames() throws SonarHostException {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR, Map.of("/api/plugins/installed", "installedPluginsOk.json"));

    var host = buildSonarHost(api);
    Set<RemotePlugin> plugins = host.getDelphiPlugins();

    assertEquals(2, plugins.size());

    var mainPlugin =
        plugins.stream()
            .filter(plugin -> "communitydelphi".equals(plugin.getPluginKey()))
            .findFirst();
    assertTrue(mainPlugin.isPresent());
    assertEquals("filename1", mainPlugin.get().getFileName());

    var secondaryPlugin =
        plugins.stream()
            .filter(plugin -> "mycustomdelphi".equals(plugin.getPluginKey()))
            .findFirst();
    assertTrue(secondaryPlugin.isPresent());
    assertEquals("filename2", secondaryPlugin.get().getFileName());
  }

  @Test
  void identifiesCorePlugin() throws SonarHostException {
    var api =
        new ResourceBackedSonarApi(
            RESOURCE_DIR, Map.of("/api/plugins/installed", "installedPluginsOk.json"));

    var host = buildSonarHost(api);
    Set<RemotePlugin> plugins = host.getDelphiPlugins();

    assertEquals(2, plugins.size());

    var mainPlugins =
        plugins.stream().filter(RemotePlugin::isCorePlugin).collect(Collectors.toSet());
    assertEquals(1, mainPlugins.size());
    assertEquals("communitydelphi", mainPlugins.stream().findFirst().get().getPluginKey());
  }

  static class ResourceBackedSonarApi implements SonarApi {
    private final Path basePath;
    private final Map<String, String> responseResources;
    private final ObjectMapper mapper;

    public ResourceBackedSonarApi(Path basePath, Map<String, String> responseResources) {
      this.basePath = basePath;
      this.responseResources = responseResources;
      this.mapper = new ObjectMapper();
    }

    @Override
    public String getHostUrl() {
      return "<DUMMY>";
    }

    private Path getPath(String url) {
      if (!responseResources.containsKey(url)) {
        throw new NotImplementedException("No resource assigned to mocked URL " + url);
      }
      return basePath.resolve(responseResources.get(url));
    }

    @Override
    public JsonNode getJson(String url) {
      try {
        return mapper.readTree(Files.newInputStream(getPath(url)));
      } catch (IOException e) {
        throw new UncheckedIOException(e);
      }
    }

    @Override
    public Path getFile(String url) {
      return getPath(url);
    }
  }
}