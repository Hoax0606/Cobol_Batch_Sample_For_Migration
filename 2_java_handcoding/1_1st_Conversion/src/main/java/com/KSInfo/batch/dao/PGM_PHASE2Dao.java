package com.KSInfo.batch.dao;

import java.util.Map;

import org.apache.ibatis.annotations.Mapper;

import com.KSInfo.batch.dto.PGM_PHASE2Dto;

@Mapper
public interface PGM_PHASE2Dao {

    int delete_01(PGM_PHASE2Dto param);

    PGM_PHASE2Dto select_01(PGM_PHASE2Dto param);

    int insert_01(PGM_PHASE2Dto param);

}