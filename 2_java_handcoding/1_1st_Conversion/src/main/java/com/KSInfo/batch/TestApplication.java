package com.KSInfo.batch;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import com.KSInfo.batch.dao.PGM_PHASE3Dao;
import com.KSInfo.batch.dto.DCL_TB_INST_MASTERDto;
import com.KSInfo.batch.dto.PGM_PHASE3Dto;
import com.KSInfo.batch.dto.SYS_COMMON_AREADto;

import java.util.HashMap;
import java.util.Map;

@SpringBootApplication
public class TestApplication {

    @Autowired
    private Phase3Dao dao;

    public static void main(String[] args) {
        ApplicationContext ctx = SpringApplication.run(TestApplication.class, args);

        // Spring이 관리하는 인스턴스를 꺼내서 호출
        TestApplication app = ctx.getBean(TestApplication.class);

        PGM_PHASE3Dto dto = new PGM_PHASE3Dto();
        // app.DELETE_TRX_DETAIL(dto);

        // ── SYS_COMMON_AREADto 디버깅 ──────────────────────────
        SYS_COMMON_AREADto sys = dto.getSYS_COMMON_AREA();

        System.out.println("=== SYS_COMMON_AREADto Init ===");
        System.out.println("SYS_RET_CODE  : " + sys.getSYS_RET_CODE());   // 0
        System.out.println("isBatchWarning: " + sys.isBatchWarning());     // false
        System.out.println("isBatchError  : " + sys.isBatchError());       // false

        sys.setBatchWarning();
        System.out.println("\n--- setBatchWarning() Call ---");
        System.out.println("SYS_RET_CODE  : " + sys.getSYS_RET_CODE());   // 4
        System.out.println("isBatchWarning: " + sys.isBatchWarning());     // true
        System.out.println("isBatchError  : " + sys.isBatchError());       // false

        sys.setBatchError();
        System.out.println("\n--- setBatchError() Call ---");
        System.out.println("SYS_RET_CODE  : " + sys.getSYS_RET_CODE());   // 8
        System.out.println("isBatchWarning: " + sys.isBatchWarning());     // false
        System.out.println("isBatchError  : " + sys.isBatchError());       // true
        // ───────────────────────────────────────────────────────

    }

    private void DELETE_TRX_DETAIL(PGM_PHASE3Dto dto) {    

        // dto.getDCL_TB_TRX_DETAIL().setDTL_SETTLE_DATE(dto.getSYS_COMMON_AREA().getSYS_BIZ_DATE());
        dto.getDCL_TB_INST_MASTER().setINST_MAST_CD("B001");
   
        try {
            // dao.select_03(dto);
            DCL_TB_INST_MASTERDto result = dao.select_03(dto);

            if (result == null) {
                System.out.println("[WARN] INST NOT FOUND: " + dto.getDCL_TB_INST_MASTER().getINST_MAST_CD());
            } else {
                System.out.println("[SUCCESS] INST_CD: "   + result.getINST_MAST_CD());
                System.out.println("[SUCCESS] INST_NAME: " + result.getINST_MAST_NAME());
                System.out.println("[SUCCESS] INST_STAT: " + result.getINST_MAST_STAT());
                System.out.println("[SUCCESS] FEE_RATE: "  + result.getINST_MAST_FEE_RATE());
            }

        } catch (Exception e) {
            System.out.println(e.getMessage());
            dto.getERR_LOG_AREA().setERR_SQLCODE(Integer.parseInt(e.getMessage()));
            dto.getERR_LOG_AREA().setERR_DESCRIPTION("TRX_DETAIL DELETE ERROR");
            // DB_ERROR(dto);
        }
    }
}


