package com.university.flight.map.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.university.flight.map.entity.AirportInfo;

import java.util.List;

public interface AirportService extends IService<AirportInfo> {

    /**
     * 根据机场代码获取机场信息
     */
    AirportInfo getByAirportCode(String airportCode);

    /**
     * 获取所有机场列表
     */
    List<AirportInfo> getAllAirports();

    /**
     * 根据城市名称搜索机场
     */
    List<AirportInfo> searchByCity(String cityName);

    /**
     * 根据国家搜索机场
     */
    List<AirportInfo> searchByCountry(String country);
}
