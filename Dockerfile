FROM gradle:7.1.1-jdk11-openj9 as build

WORKDIR /home/gradle/project
COPY build.gradle settings.gradle /home/gradle/project/
COPY app/ /home/gradle/project/app/
RUN gradle bootJar
CMD ["gradle", "bootRun"]

FROM openjdk:11-jre-slim
EXPOSE 8080
COPY run.sh /run.sh
RUN chmod a+x /run.sh
COPY --from=build /home/gradle/project/app/build/libs/springboot-server-0.0.1-SNAPSHOT.jar /app.jar
ENTRYPOINT ["sh", "/run.sh"]
