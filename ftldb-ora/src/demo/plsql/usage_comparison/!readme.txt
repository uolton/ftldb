====
    Copyright 2014-2016 Victor Osolovskiy, Sergey Navrotskiy

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
====

Demo from the main README.

1. Connect to the demo schema and run `install.sql` from the current directory.

2. Explore the results of execution.

3. Run in the command line with proper FTL arguments (and possibly different classpath):

    java -cp .:../../java/*:$ORACLE_HOME/jdbc/lib/ojdbc6.jar ftldb.CommandLine @orders.ftl "localhost:1521/orcl" "scott" "tiger" 1> orders.sql

4. See the `orders.sql` file.
