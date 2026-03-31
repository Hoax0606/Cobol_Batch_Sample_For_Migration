package com.KSInfo.batch.dao;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.KSInfo.batch.dto.DCL_TB_STG_TRXDto;
import com.KSInfo.batch.dto.DCL_TB_NET_SUMMARYDto;
import com.KSInfo.batch.dto.DCL_TB_INST_MASTERDto;
import com.KSInfo.batch.dto.PGM_PHASE3Dto;

@Mapper
public interface PGM_PHASE3Dao {

    List<DCL_TB_STG_TRXDto> select_01(PGM_PHASE3Dto dto, @Param("limit") int limit, @Param("offset") int offset);

    List<DCL_TB_NET_SUMMARYDto> select_02(PGM_PHASE3Dto dto, @Param("limit") int limit, @Param("offset") int offset);

    DCL_TB_INST_MASTERDto select_03(PGM_PHASE3Dto dto);

    int insert_01(PGM_PHASE3Dto dto);

    int update_01(PGM_PHASE3Dto dto);

    int delete_01(PGM_PHASE3Dto dto);

    int delete_02(PGM_PHASE3Dto dto);

    int insert_02(PGM_PHASE3Dto dto);

    int delete_03(PGM_PHASE3Dto dto);

    int insert_03(PGM_PHASE3Dto dto);

}