package com.university.flight.info;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
@MapperScan("com.university.flight.info.mapper")
public class FlightInfoServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(FlightInfoServiceApplication.class, args);
    }
}