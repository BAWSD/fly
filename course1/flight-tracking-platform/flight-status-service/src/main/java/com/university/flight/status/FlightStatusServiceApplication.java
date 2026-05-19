package com.university.flight.status;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableDiscoveryClient
@EnableScheduling
@MapperScan("com.university.flight.status.mapper")
public class FlightStatusServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(FlightStatusServiceApplication.class, args);
    }
}