package com.KSInfo.batch.dao;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.KSInfo.batch.dto.DCL_TB_INST_MASTERDto;
import com.KSInfo.batch.dto.DCL_TB_STG_TRXDto;
import com.KSInfo.batch.dto.DCL_TB_NET_SUMMARYDto;
import com.KSInfo.batch.dto.PGM_PHASE3Dto;

@Mapper
public interface PGM_PHASE3Dao {

    List<DCL_TB_STG_TRXDto> select_01(PGM_PHASE3Dto param, @Param("limit") int limit, @Param("offset") int offset);

    List<DCL_TB_NET_SUMMARYDto> select_02(PGM_PHASE3Dto param, @Param("limit") int limit, @Param("offset") int offset);

    // PGM_PHASE3Dto select_03(PGM_PHASE3Dto dto);
    DCL_TB_INST_MASTERDto select_03(PGM_PHASE3Dto param);

    int insert_01(PGM_PHASE3Dto param);

    int update_01(PGM_PHASE3Dto param);

    int delete_01(PGM_PHASE3Dto param);

    int delete_02(PGM_PHASE3Dto param);

    int insert_02(PGM_PHASE3Dto param);

    int delete_03(PGM_PHASE3Dto param);

    int insert_03(PGM_PHASE3Dto param);

}