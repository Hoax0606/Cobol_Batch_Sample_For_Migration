package com.KSInfo.batch.dto;

import lombok.Data;
import java.math.BigDecimal;

import com.KSInfo.batch.common.dto.*;

@Data
public class PGM_PHASE1Dto{
    private String IN_REC = "";
    private String OUT_REC = "";
    private String ERR_REC = "";

    private SORT_RECDto SORT_RECDto = new SORT_RECDto();
    private SYS_COMMON_AREADto SYS_COMMON_AREADto = new SYS_COMMON_AREADto();     //COPY SYS-COM.
    private ERR_LOG_AREADto ERR_LOG_AREADto = new ERR_LOG_AREADto(); //COPY ERR-LOG.
    private FILE_CONTROL_RECDto FILE_CONTROL_RECDto = new FILE_CONTROL_RECDto(); //COPY ERR-LOG.
// 01  HEADER_REC REDEFINES FILE_CONTROL_REC.
// 01  TRAILER_REC REDEFINES FILE_CONTROL_REC.
    private TRX_RECORDDto TRX_RECORDDto = new TRX_RECORDDto(); //COPY TRX-REC.


    private DCL_TB_STG_TRXDto DCL_TB_STG_TRXDto = new DCL_TB_STG_TRXDto();
    private DCL_TB_INST_MASTERDto DCL_TB_INST_MASTERDto = new DCL_TB_INST_MASTERDto();
    private DCL_TB_NET_SUMMARYDto DCL_TB_NET_SUMMARYDto = new DCL_TB_NET_SUMMARYDto();
    private DCL_TB_TRX_DETAILDto DCL_TB_TRX_DETAILDto = new DCL_TB_TRX_DETAILDto();
    private DCL_TB_INST_DAILY_STATDto DCL_TB_INST_DAILY_STATDto = new DCL_TB_INST_DAILY_STATDto();
    private DCL_TB_BATCH_LOGDto DCL_TB_BATCH_LOGDto = new DCL_TB_BATCH_LOGDto();
    private WS_FILE_STATUSDto WS_FILE_STATUSDto = new WS_FILE_STATUSDto();
    private WS_FLAGSDto_1 WS_FLAGSDto_1 = new WS_FLAGSDto_1();
    private WS_CALC_TOTALSDto WS_CALC_TOTALSDto = new WS_CALC_TOTALSDto();
    private BigDecimal WS_CALC_AMT = BigDecimal.ZERO;
    private WS_WORK_AREASDto_1 WS_WORK_AREASDto_1 = new WS_WORK_AREASDto_1(); // BLOGSVR과 같음
    private String WS_LOG_BUFFER = "";
    private int WS_LOG_PTR = 1;
    private String WS_LOG_TRX_AMT = "";
    private int WS_INSPECT_CNT = 0;

    private String WS_PROG_NAME = "PGM_PHASE1";
    private String WS_PHASE_ID = "PHASE1";
    private String WS_HEADER_DATE = "";
    private String WS_TRAILER_COUNT = "";
    private int WS_COMMIT_LIMIT = 1000;
    private int WS_REC_LENGTH = 50;
    private String  WS_ERR_FIELD = "E000";
    private String  WS_ERR_CODE_SEQ = "E001";
    private String  WS_ERR_CODE_INST = "E002";
    private String  WS_ERR_CODE_ACC = "E003";
    private String  WS_ERR_CODE_TYPE = "E004";
    private String  WS_ERR_CODE_AMT = "E005";
    private String  WS_ERR_CODE_CTRL = "E006";
    private String  WS_ERR_CODE_OVF = "E007";

}