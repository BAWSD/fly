package com.university.flight.status.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.university.flight.status.entity.FlightStatus;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface FlightStatusMapper extends BaseMapper<FlightStatus> {

	@Select("""
		SELECT fs.*
		FROM flight_status fs
		JOIN (
			SELECT flight_number, MAX(last_updated) AS max_time
			FROM flight_status
			WHERE current_status IN ('DEPARTED','IN_AIR','BOARDING','ON_TIME','DELAYED')
			GROUP BY flight_number
		) m
		ON fs.flight_number = m.flight_number AND fs.last_updated = m.max_time
		ORDER BY fs.last_updated ASC
	""")
	List<FlightStatus> selectLatestActiveFlights();
}
