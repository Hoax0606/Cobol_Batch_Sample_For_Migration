package com.KSInfo.batch.dao;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;

import com.KSInfo.batch.dto.DCL_TB_INST_MASTERDto;
import com.KSInfo.batch.dto.PGM_PHASE3Dto;

@Mapper
public interface PGM_PHASE3Dao {

    List<Map<String, Object>> select_01(Map<String, Object> param);

    List<Map<String, Object>> select_02(Map<String, Object> param);

    // PGM_PHASE3Dto select_03(PGM_PHASE3Dto dto);
    DCL_TB_INST_MASTERDto select_03(PGM_PHASE3Dto param);

    int insert_01(Map<String, Object> param);

    int update_01(Map<String, Object> param);

    int delete_01(PGM_PHASE3Dto dto);

    int delete_02(Map<String, Object> param);

    int insert_02(Map<String, Object> param);

    int delete_03(Map<String, Object> param);

    int insert_03(Map<String, Object> param);

}