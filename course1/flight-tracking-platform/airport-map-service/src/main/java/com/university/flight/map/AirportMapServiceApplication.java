package com.university.flight.map;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
@MapperScan("com.university.flight.map.mapper")
public class AirportMapServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(AirportMapServiceApplication.class, args);
    }
}
