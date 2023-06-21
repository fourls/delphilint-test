/*
 * DelphiLint Server
 * Copyright (C) 2023 Integrated Application Development
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */
package au.com.integradev.delphilint;

import au.com.integradev.delphilint.server.LintServer;
import java.io.IOException;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class App {
  private static final Logger LOG = LogManager.getLogger(App.class);

  public static void main(String[] args) throws IOException {
    int port = 14000;
    if (args.length > 0) {
      port = Integer.parseInt(args[0]);
    }
    LOG.info("Starting server on port {}", port);
    var server = new LintServer(port);
    server.run();
    LOG.info("Server stopped");
  }
}
