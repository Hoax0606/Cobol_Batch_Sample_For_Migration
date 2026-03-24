package com.KSInfo.batch.dao;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface Phase3Dao {

    List<Map<String, Object>> select_01(Map<String, Object> param);

    List<Map<String, Object>> select_02(Map<String, Object> param);

    Map<String, Object> select_03(Map<String, Object> param);

    int insert_01(Map<String, Object> param);

    int update_01(Map<String, Object> param);

    int delete_01(Map<String, Object> param);

    int delete_02(Map<String, Object> param);

    int insert_02(Map<String, Object> param);

    int delete_03(Map<String, Object> param);

    int insert_03(Map<String, Object> param);

}