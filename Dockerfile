FROM maven:3.8.4-openjdk-11-slim as builder
RUN apt-get update && apt-get install -y git
RUN cd /usr/src \
  && git clone https://github.com/spring-projects/spring-petclinic.git \
  && cd spring-petclinic \
  && subs='  <dependency>\n    <groupId>io.micrometer</groupId>\n    <artifactId>micrometer-registry-prometheus</artifactId>\n  </dependency>' \
  && sed -i "0,/<dependencies>/{s|<dependencies>|<dependencies>\n\n${subs}\n|}" pom.xml \
  && sed -i 's/localhost/db/' ./src/main/resources/application-postgres.properties \
  && echo 'management.endpoints.web.exposure.include=health,info,metrics,prometheus' >> ./src/main/resources/application-postgres.properties \
  && mvn package

FROM openjdk:19-jdk-alpine
RUN cd /usr/local/bin
COPY --from=builder /usr/src/spring-petclinic/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-Dspring.profiles.active=postgres", "-jar", "app.jar"]