package com.KSInfo.batch.dao;

import java.util.Map;

import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface BlogsvrDao {

    int insert_01(Map<String, Object> param);

    Map<String, Object> select_01(Map<String, Object> param);

    int update_01(Map<String, Object> param);

}