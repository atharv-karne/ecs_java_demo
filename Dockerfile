FROM openjdk:11-jre-slim

WORKDIR /app

COPY target/demo-0.0.1-SNAPSHOT.jar /app/demo.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "/app/demo.jar"]
