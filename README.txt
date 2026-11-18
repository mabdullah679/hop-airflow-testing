HOP-AIRFLOW-TESTING (plain-text version of README.md)

What it is
A small Docker Compose setup that starts two tools on your own computer: Apache Hop (a web page for building data pipelines) and Apache Airflow (a job scheduler). One command then checks that both are answering.

How it fits together
Running "make up" tells Docker to start two containers. Hop is reachable at http://localhost:18080 and Airflow at http://localhost:28080. Running "make verify" asks each one for a web page and succeeds only if both reply with the success code 200. The only thing not on your computer is the two images, which are downloaded from Docker Hub the first time.

What you need
Docker running (with the compose feature), the make and curl programs, and ports 18080 and 28080 free. jq is optional. You do not need Java, Python or Airflow installed.

How to run it
1. Run: make up. The first time it downloads images, and Airflow takes a minute or two to set itself up.
2. Run: make ps. Wait until both containers say healthy.
3. Run: make verify. It prints both codes and only succeeds if both are 200.
4. Open the two web addresses above. Airflow makes a user called admin for you; its generated password is stored in the file /opt/airflow/standalone_admin_password.txt inside the airflow container (read it with: docker exec airflow cat /opt/airflow/standalone_admin_password.txt).
5. Run: make down to stop everything and delete its data.

If something goes wrong
If a port is already used, change the number on the left of the ports line in docker-compose.yml and the matching address in the Makefile. If verify shows 000, the service is not ready yet; look at make logs and wait.

What each command does
make up starts both. make ps shows their state. make proof prints the codes. make verify succeeds only if both are 200. make logs follows the logs. make down removes the containers and their data. Hop answers the front page with a redirect (302), which is why the check follows redirects.

Tests
There are no unit tests. The check is make verify against the running stack; it needs Docker and internet access to download images. The automatic check on GitHub does the same things: validates the compose file, starts the stack, waits for verify to pass, shuts it down, and scans for leaked passwords.

Files
docker-compose.yml defines the two services. Makefile holds the commands. .github/workflows/ci.yml is the automatic check. real-quick-check.txt is the owner's scratch notes. CLAUDE.md is notes for Claude Code.

Design notes
Each health check uses a tool that the image really contains. The Airflow image has no wget, so the old wget check could never pass and the container showed unhealthy even though it worked; it now uses curl. The Hop image is "latest", so its underlying operating system can change between downloads; Airflow is pinned to version 2.9.3. Airflow standalone runs everything in one container, which is fine for testing but not for production. Container names are fixed, so two copies cannot run at once.
