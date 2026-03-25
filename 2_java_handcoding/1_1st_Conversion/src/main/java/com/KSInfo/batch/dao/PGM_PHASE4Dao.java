package com.KSInfo.batch.dao;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface PGM_PHASE4Dao {

    List<Map<String, Object>> select_01(Map<String, Object> param);

}