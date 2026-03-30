package com.KSInfo.batch.pgm;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import com.KSInfo.batch.dao.PGM_BLOGSVRDao;
import com.KSInfo.batch.dto.PGM_BLOGSVRDto;
import com.KSInfo.batch.dto.DCL_TB_BATCH_LOGDto;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
public class PGM_BLOGSVR {
    @Autowired
    private PGM_BLOGSVRDao dao;
    //!!1.PROCEDURE                      DIVISION USING DCL-TB-BATCH-LOG.
    
    private DCL_TB_BATCH_LOGDto DCL_TB_BATCH_LOGDto = new DCL_TB_BATCH_LOGDto();
    private int SQLCODE = 0;
    

    public void MAIN(PGM_BLOGSVRDto dto){
        //!!2.PROCEDURE                      DIVISION USING DCL-TB-BATCH-LOG.

        dto.getDCL_TB_BATCH_LOGDto().setBLG_RETURN_CODE(0);

        DB_CONNECT(dto);

        if(DCL_TB_BATCH_LOGDto.getBLG_RETURN_CODE() != 0) {
            return;
        } else {
            // CONTINUE
        }

        if (dto.getDCL_TB_BATCH_LOGDto().getBLG_ACTION().equals(dto.getDCL_TB_BATCH_LOGDto().BLG_START)) {
            BATCHLOG_START(dto);
        } 
        else if (dto.getDCL_TB_BATCH_LOGDto().getBLG_ACTION().equals(dto.getDCL_TB_BATCH_LOGDto().BLG_END)) {
            BATCHLOG_END(dto);
        } 
        else {
            log.info("> [BLOGSVR] UNKNOWN ACTION: " + dto.getDCL_TB_BATCH_LOGDto().getBLG_ACTION());
            DCL_TB_BATCH_LOGDto.setBLG_RETURN_CODE(8);
        }

        if (DCL_TB_BATCH_LOGDto.getBLG_RETURN_CODE() == 0) {
            // !! EXEC SQL COMMIT            END-EXEC
        } else {
             // CONTINUE
        }

        // ctx.close();
        //GOBACK.!!

    }

    private void DB_CONNECT(PGM_BLOGSVRDto dto) {
        // ACCEPT WS-DATASRC      FROM ENVIRONMENT 'GIXSQL_DB_CONN'.
        // ACCEPT WS-USER         FROM ENVIRONMENT 'GIXSQL_USER'.
        // ACCEPT WS-PWD          FROM ENVIRONMENT 'GIXSQL_PWD'.

        if (dto.getWS_DB_CONNDto().getWS_DATASRC().equals("")) {
            log.info("> [BLOGSVR] GIXSQL_DB_CONN NOT SET, SKIP");
            DCL_TB_BATCH_LOGDto.setBLG_RETURN_CODE(8);
        }
        else {
                // EXEC SQL 
                //     CONNECT :WS-USER IDENTIFIED BY :WS-PWD
                //             USING :WS-DATASRC
                // END-EXEC.
                
                if (SQLCODE == 0) {
                    // CONTINUE
                } else {
                    dto.getWS_WORK_AREASDto().setWS_SQLCODE_DISP(SQLCODE);
                    log.info("> [BLOGSVR] DB CONNECT FAILED. SQLCODE=" + dto.getWS_WORK_AREASDto().getWS_SQLCODE_DISP());
                    dto.getDCL_TB_BATCH_LOGDto().setBLG_RETURN_CODE(8);
                }
        }

    }

    private void BATCHLOG_START(PGM_BLOGSVRDto dto) {
        DCL_TB_BATCH_LOGDto.setBLG_START_DT(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")));
        DCL_TB_BATCH_LOGDto.setBLG_END_DT("");
        DCL_TB_BATCH_LOGDto.setBLG_STAT("R");
        DCL_TB_BATCH_LOGDto.setBLG_PROC_CNT(0);
        DCL_TB_BATCH_LOGDto.setBLG_ERR_CNT(0);

        try {
            dao.insert_01(dto);

            if (SQLCODE != 0) {
                dto.getWS_WORK_AREASDto().setWS_SQLCODE_DISP(SQLCODE);
                log.info("> [BLOGSVR] START INSERT ERROR. SQLCODE=" + dto.getWS_WORK_AREASDto().getWS_SQLCODE_DISP());
                dto.getDCL_TB_BATCH_LOGDto().setBLG_RETURN_CODE(8);
            } else {
                // EXEC SQL COMMIT            END-EXEC

                try {
                    dao.select_01(dto);

                    if (SQLCODE != 0) {
                        dto.getWS_WORK_AREASDto().setWS_SQLCODE_DISP(SQLCODE);
                        log.info("> [BLOGSVR] BATCH_ID SELECT ERROR. SQLCODE=" + dto.getWS_WORK_AREASDto().getWS_SQLCODE_DISP());
                        dto.getDCL_TB_BATCH_LOGDto().setBLG_RETURN_CODE(8);
                    } else {
                        // CONTINUE
                    }
                } catch (Exception e) {

                }
            }
        } catch (Exception e) {
            
        }

        

    }

    private void BATCHLOG_END(PGM_BLOGSVRDto dto) {
        DCL_TB_BATCH_LOGDto.setBLG_END_DT(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")));
        
        try {
            dao.update_01(dto);

            if (SQLCODE != 0) {
                dto.getWS_WORK_AREASDto().setWS_SQLCODE_DISP(SQLCODE);
                log.info("> [BLOGSVR] END UPDATE ERROR. SQLCODE=" + dto.getWS_WORK_AREASDto().getWS_SQLCODE_DISP());
                dto.getDCL_TB_BATCH_LOGDto().setBLG_RETURN_CODE(8);
            } else {
                // CONTINUE
            }
        } catch (Exception e) {
            
        }
        
    }

}
