# security-assessment
Docker based security assessment script that performs tests on target host/IP.

## Advantages/Motivations behind this project
* Multiple security/reconnaissance tools in a single script
* Automated
* Platform independent
* Effort & time reduction 

## Requirements/Assumptions
1. You have an Internet connection.
2. 'docker' daemon is running. If it's not, run `sudo systemctl start docker`.
3. You own/have control over the target domain/IP address. 
4. You have both files i.e. shell script and Dockerfile in the same directory.

## How to use both the files?
1. Download `sec_assessment.sh` and `Dockerfile`
2. Build Docker image from Dockerfile using `docker build --tag sec_assessment .`
3. Run Docker container using `docker run -it --volume "$(pwd)"/../results:/home sec_assessment:latest`
4. Run `sec_assessment.sh` inside container
