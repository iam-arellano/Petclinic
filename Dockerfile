FROM openjdk:8
EXPOSE 8089
ADD target/petclinic.war petclinic.war
ENTRYPOINT ["java","-jar","/petclinic.war"]
