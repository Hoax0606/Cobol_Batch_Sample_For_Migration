package com.KSInfo.batch.dao;

import org.apache.ibatis.annotations.Mapper;

import com.KSInfo.batch.dto.PGM_BLOGSVRDto;

@Mapper
public interface PGM_BLOGSVRDao {

    int insert_01(PGM_BLOGSVRDto param);

    PGM_BLOGSVRDto select_01(PGM_BLOGSVRDto param);

    int update_01(PGM_BLOGSVRDto param);

}