#FROM tomcat:latest
#WORKDIR /usr/local/tomcat/webapps
#COPY ./target/ashwin-web.war /usr/local/tomcat/webapps/ashwin-web.war
#EXPOSE 8080
#CMD ["startup.sh", "run"]

FROM openjdk:8
EXPOSE 8080
ADD target/ashwin-web-0.0.1-SNAPSHOT.jar ashwin-web-0.0.1-SNAPSHOT.jar
ENTRYPOINT ["java","-jar","/ashwin-web-0.0.1-SNAPSHOT.jar"]
