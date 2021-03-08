#!/bin/bash

set -e

JDK_PATH="/usr/lib/jvm/enclave_benchmark/jre"

# 1. Install mvn
apt-get update
apt-get -y install maven

# 2. Create the demo
rm -rf tomcat-demo && mkdir tomcat-demo && cd $_

echo '
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example.employees</groupId>
    <artifactId>employees-app</artifactId>
    <packaging>jar</packaging>
    <version>1.0-SNAPSHOT</version>
    <name>employees-app Maven Webapp</name>
    <url>http://maven.apache.org</url>

    <properties>
        <tomcat.version>9.0.17</tomcat.version>
        <maven.compiler.plugin.version>3.8.0</maven.compiler.plugin.version>
        <java.version>11</java.version>
        <maven.assembly.plugin.version>3.1.1</maven.assembly.plugin.version>
        <logback.version>1.2.3</logback.version>
        <sl4j.version>1.7.26</sl4j.version>
        <logstash.logback.encoder.version>5.3</logstash.logback.encoder.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.apache.tomcat.embed</groupId>
            <artifactId>tomcat-embed-core</artifactId>
            <version>${tomcat.version}</version>
        </dependency>
        <dependency>
            <groupId>ch.qos.logback</groupId>
            <artifactId>logback-classic</artifactId>
            <version>${logback.version}</version>
        </dependency>
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>jul-to-slf4j</artifactId>
            <version>${sl4j.version}</version>
        </dependency>
        <dependency>
            <groupId>net.logstash.logback</groupId>
            <artifactId>logstash-logback-encoder</artifactId>
            <version>${logstash.logback.encoder.version}</version>
        </dependency>
    </dependencies>

    <build>
        <finalName>employees-app</finalName>
        <resources>
            <resource>
                <directory>src/main/webapp</directory>
                <targetPath>META-INF/resources</targetPath>
            </resource>
            <resource>
                <directory>src/main/resources</directory>
            </resource>
        </resources>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>${maven.compiler.plugin.version}</version>
                <inherited>true</inherited>
                <configuration>
                    <release>${java.version}</release>
                    <!-- for dummy IntelliJ -->
                    <source>${java.version}</source>
                    <target>${java.version}</target>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-assembly-plugin</artifactId>
                <version>${maven.assembly.plugin.version}</version>
                <configuration>
                    <descriptorRefs>
                        <descriptorRef>jar-with-dependencies</descriptorRef>
                    </descriptorRefs>
                    <finalName>employees-app-${project.version}</finalName>
                    <archive>
                        <manifest>
                            <mainClass>com.example.employees.Main</mainClass>
                        </manifest>
                    </archive>
                </configuration>
                <executions>
                    <execution>
                        <phase>package</phase>
                        <goals>
                            <goal>single</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>' > pom.xml

mkdir -p src/main/webapp
echo '
<html>
<body>
<h2>Hello World!</h2>
</body>
</html>
' > src/main/webapp/index.html

mkdir -p src/main/java/com/example/employees
echo '
package com.example.employees;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;

@WebServlet(urlPatterns = "/employee", loadOnStartup = 1)
public class EmployeeServlet extends HttpServlet {

    private static final Logger LOGGER = LoggerFactory.getLogger(EmployeeServlet.class);

    @Override
    public void init() {
        LOGGER.info("Initializing {}", EmployeeServlet.class);
    }


    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        PrintWriter writer = resp.getWriter();

        writer.println("<html><title>EMPLOYEES</title><body>");
        writer.println("<h1>Employees works!</h1>");
        writer.println("</body></html>");
    }

    @Override
    public void destroy() {
        LOGGER.info("Destroying {}", EmployeeServlet.class);
    }
}' > src/main/java/com/example/employees/EmployeeServlet.java

echo '
package com.example.employees;

import org.apache.catalina.*;
import org.apache.catalina.core.StandardContext;
import org.apache.catalina.startup.Tomcat;
import org.apache.catalina.webresources.DirResourceSet;
import org.apache.catalina.webresources.JarResourceSet;
import org.apache.catalina.webresources.StandardRoot;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.URL;
import java.util.Optional;
import org.slf4j.bridge.SLF4JBridgeHandler;


public class Main {
    public static final Integer PORT = Optional.ofNullable(System.getenv("PORT")).map(Integer::parseInt).orElse(8080);

    public static final String STATICDIR = Optional.ofNullable(System.getenv("STATICDIR")).orElse("/tmp/tomcat-static");
    public static final String TMPDIR = Optional.ofNullable(System.getenv("TMPDIR")).orElse("/tmp/tomcat-tmp");

    public static void main(String[] args) throws Exception {
        // initialize logback
        SLF4JBridgeHandler.removeHandlersForRootLogger();
        SLF4JBridgeHandler.install();

        Tomcat tomcat = new Tomcat();
        tomcat.setBaseDir(TMPDIR);
        tomcat.setPort(PORT);

        tomcat.setConnector(tomcat.getConnector());
        // prevent register jsp servlet
        tomcat.setAddDefaultWebXmlToWebapp(false);

        String contextPath = ""; // root context
        new File(STATICDIR).mkdirs();
        String docBase = new File(STATICDIR).getCanonicalPath();
        Context context = tomcat.addWebapp(contextPath, docBase);
        context.setAddWebinfClassesResources(true); // process /META-INF/resources for static

        // fix Illegal reflective access by org.apache.catalina.loader.WebappClassLoaderBase
        // https://github.com/spring-projects/spring-boot/issues/15101#issuecomment-437384942
        StandardContext standardContext = (StandardContext) context;
        standardContext.setClearReferencesObjectStreamClassCaches(false);
        standardContext.setClearReferencesRmiTargets(false);
        standardContext.setClearReferencesThreadLocals(false);


        HttpServlet servlet = new HttpServlet() {
            @Override
            protected void doGet(HttpServletRequest req, HttpServletResponse resp)
                    throws ServletException, IOException {
                PrintWriter writer = resp.getWriter();

                writer.println("<html><title>Welcome</title><body>");
                writer.println("<h1>Have a Great Day!</h1>");
                writer.println("</body></html>");
            }
        };
        String servletName = "Servlet1";
        String urlPattern = "/go";
        tomcat.addServlet(contextPath, servletName, servlet);
        context.addServletMappingDecoded(urlPattern, servletName);


        WebResourceRoot webResourceRoot = new StandardRoot(context);


        // Additions to make serving static work
        final String defaultServletName = "default";
        Wrapper defaultServlet = context.createWrapper();
        defaultServlet.setName(defaultServletName);
        defaultServlet.setServletClass("org.apache.catalina.servlets.DefaultServlet");
        defaultServlet.addInitParameter("debug", "0");
        defaultServlet.addInitParameter("listings", "false");
        defaultServlet.setLoadOnStartup(1);
        context.addChild(defaultServlet);
        context.addServletMappingDecoded("/", defaultServletName);
        // display index.html on http://127.0.0.1:8080
        context.addWelcomeFile("index.html");

        // add itself jar with static resources (html) and annotated servlets

        String webAppMount = "/WEB-INF/classes";
        WebResourceSet webResourceSet;
        if (!isJar()) {
                // potential dangerous - if last argument will "/" that means tomcat will serves self jar with .class files
            webResourceSet = new DirResourceSet(webResourceRoot, webAppMount, getResourceFromFs(), "/");
        } else {
            webResourceSet = new JarResourceSet(webResourceRoot, webAppMount, getResourceFromJarFile(), "/");
        }
        webResourceRoot.addJarResources(webResourceSet);
        context.setResources(webResourceRoot);

        // need for proper destroying servlets
        Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    tomcat.getServer().stop();
               } catch (LifecycleException e) {
                    e.printStackTrace();
                }
            }
        }));


        tomcat.start();
        tomcat.getServer().await();
    }


    public static boolean isJar() {
        URL resource = Main.class.getResource("/");
        return resource == null;
    }

    public static String getResourceFromJarFile() {
        File jarFile = new File(System.getProperty("java.class.path"));
        return jarFile.getAbsolutePath();
    }

    public static String getResourceFromFs() {
        URL resource = Main.class.getResource("/");
        return resource.getFile();
    }

}' > src/main/java/com/example/employees/Main.java

mkdir -p src/main/resources
echo '
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="net.logstash.logback.encoder.LogstashEncoder" />
    </appender>

    <root level="debug">
        <appender-ref ref="STDOUT" />
    </root>
</configuration>' > src/main/resources/logback.xml

# 3. Build the Fat JAR file with Maven
export LD_LIBRARY_PATH=/opt/occlum/toolchains/gcc/x86_64-linux-musl/lib
export JAVA_HOME=${JDK_PATH}
mvn -q clean package
