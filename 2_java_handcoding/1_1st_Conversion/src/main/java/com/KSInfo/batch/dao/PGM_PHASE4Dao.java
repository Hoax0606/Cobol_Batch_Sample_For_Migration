package com.KSInfo.batch.dao;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;

import com.KSInfo.batch.dto.DCL_TB_NET_SUMMARYDto;
import com.KSInfo.batch.dto.PGM_PHASE4Dto;

@Mapper
public interface PGM_PHASE4Dao {

    List<DCL_TB_NET_SUMMARYDto> select_01(PGM_PHASE4Dto param);

}