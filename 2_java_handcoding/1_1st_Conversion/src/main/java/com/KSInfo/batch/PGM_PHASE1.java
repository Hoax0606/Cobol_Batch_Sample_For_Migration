package com.KSInfo.batch;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;

import com.KSInfo.batch.dto.PGM_PHASE1Dto;

import lombok.extern.slf4j.Slf4j;
public class PGM_PHASE1 {
    //!! 삭제?
    // @Autowired
    // private PGM_BLOGSVR PGM_BLOGSVR;

    // @Autowired
    // private PGM_BLOGSVRDto PGM_BLOGSVRDto;
    //----------------------------------------------

    // 파일 핸들 (클래스 레벨)
    private BufferedReader IN_FILE;
    private BufferedWriter OUT_FILE;
    private BufferedWriter ERR_FILE;

    // 설정 파일에서 경로를 읽어와 변수에 할당합니다.
    @Value("${batch.file.path.input}")
    private String IN_FILE_Path;
    @Value("${batch.file.path.output}")
    private String OUT_FILE_Path;
    @Value("${batch.file.path.error}")
    private String ERR_FILE_Path;

    public void MAIN(PGM_PHASE1Dto dto) {
        INIT(dto);
    // !!나중에 수정 및 확인 필요
    
    // SORT SORT-FILE
    //     ASCENDING KEY SR-INST-CD
    //     INPUT  PROCEDURE IS INPUT-PROC-000
    //     OUTPUT PROCEDURE IS OUTPUT-PROC-000.


        //SORT_RECDto
        List<SORT_RECDto> sortList = new ArrayList<>(); //     // PGM_PHASE1Dto에 이걸 추가 or 클래스 레벨에 선언 private List<SORT_RECDto> sortList = new ArrayList<>();
        // 1. INPUT PROCEDURE IS INPUT-PROC-000
        INPUT_PROC(dto, sortList);
        // 2. ASCENDING KEY SR-INST-CD (기관코드 기준 오름차순 정렬)
        sortList.sort((a, b) -> a.getSR_INST_CD().compareTo(b.getSR_INST_CD()));
        // 3. OUTPUT PROCEDURE IS OUTPUT-PROC-000
        OUTPUT_PROC(dto, sortList);
        //===========================

        CHECK_COUNT(dto);
        FINALIZE(dto);

        dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE());
        System.exit(dto.getSYS_COMMON_AREADto().getSYS_RET_CODE());
    }

    private void INIT(PGM_PHASE1Dto dto) {
        dto.getSYS_COMMON_AREADto().setSYS_JOB_ID(dto.getWS_PHASE_ID());
        dto.getSYS_COMMON_AREADto().setSYS_BIZ_DATE(LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd")));
            
        try {
            BLOGSVR_START(dto);

            //!! 나중에 다시 보기 (방법2)
            // OPEN INPUT  IN-FILE
            // OUTPUT OUT-FILE
            // OUTPUT ERR-FILE.

            // OPEN INPUT  IN-FILE
            try {
                // SELECT IN-FILE ASSIGN TO 'INFILE_VAR'
                IN_FILE = new BufferedReader(new FileReader(IN_FILE_Path));
                OUT_FILE = new BufferedWriter(new FileWriter(OUT_FILE_Path));
                ERR_FILE = new BufferedWriter(new FileWriter(ERR_FILE_Path));
                dto.getWS_FILE_STATUSDto().setWS_IN_STAT("00");//성공
            } catch (FileNotFoundException e) {
                dto.getWS_FILE_STATUSDto().setWS_IN_STAT("35");// 파일 없음 에러코드
            } catch (IOException e) {
                dto.getWS_FILE_STATUSDto().setWS_IN_STAT("30"); // 실패
            }
            
            //--------------------------------

            if (!dto.getWS_FILE_STATUSDto().getWS_IN_STAT().equals("00")) {

                dto.getERR_LOG_AREADto().setERR_DESCRIPTION("INPUT FILE OPEN ERROR");
                ERROR_LOG(dto);
                dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(
                    dto.getSYS_COMMON_AREADto().BATCH_ERROR
                );
                FINALIZE(dto);
                System.exit(dto.getSYS_COMMON_AREADto().getSYS_RET_CODE());
            } else {
                // CONTINUE
            }


            if (!dto.getWS_FILE_STATUSDto().getWS_OUT_STAT().equals("00")
                || !dto.getWS_FILE_STATUSDto().getWS_ERR_STAT().equals("00")) {

                dto.getERR_LOG_AREADto().setERR_DESCRIPTION("OUTPUT FILE OPEN ERROR");
                ERROR_LOG(dto);
                dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(
                    dto.getSYS_COMMON_AREADto().BATCH_ERROR
                );
                FINALIZE(dto);
                System.exit(dto.getSYS_COMMON_AREADto().getSYS_RET_CODE());
            } else {
                // CONTINUE
            }
            
        } catch (Exception e) {
            // TODO: handle exception
        }


        }
    
    private void INPUT_PROC(PGM_PHASE1Dto dto) {
        // MOVE 'N' TO WS-EOF-FLAG
        dto.getWS_FLAGSDto().setWS_EOF_FLAG("N");
        // READ IN-FILE AT END MOVE 'Y' TO WS-EOF-FLAG
            //BufferedReader.readLine()은 IOException을 throws하도록 선언되어 있어서, Java 컴파일러가 반드시 try-catch 또는 throws 선언을 요구합니다.
         try {
            String line = IN_FILE.readLine();
            if (line == null) { // 파일 끝에 도달 했는가
                // AT END
                dto.getWS_FLAGSDto().setWS_EOF_FLAG("Y");
            } else {
                // NOT AT END
                dto.setIN_REC(line);
            }

         }catch (IOException e){
            // COBOL 원본에 없는 처리(클로드가 임의로 작성해준것 - 코볼 소스에는 없음)
            // dto.getERR_LOG_AREADto().setERR_DESCRIPTION("INPUT FILE READ ERROR");
            // ERROR_LOG(dto);
            // dto.getWS_FLAGSDto().setWS_EOF_FLAG("Y");

         }

        // PERFORM INPUT-PROC-LOOP-000 UNTIL WS-EOF
        while (!dto.getWS_FLAGSDto().getWS_EOF_FLAG().equals(dto.getWS_FLAGSDto().WS_EOF)) {
        INPUT_PROC_LOOP(dto);
    }
    
    }
    
    private void INPUT_PROC_LOOP(PGM_PHASE1Dto dto) {
        // MOVE IN-REC TO FILE-CONTROL-REC
        dto.getFILE_CONTROL_RECDto().setFILE_CONTROL_REC(dto.getIN_REC());
        
        // EVALUATE TRUE
        // WHEN IS-HEADER
        if (dto.getFILE_CONTROL_RECDto().checkIS_HEADER()) {
            PROCESS_HEADER(dto);
            // WHEN IS-TRAILER
        } else if (dto.getFILE_CONTROL_RECDto().checkIS_TRAILER()) {
            PROCESS_TRAILER(dto);
            // WHEN IS-DATA
        } else if (dto.getFILE_CONTROL_RECDto().checkIS_DATA()) {
            // MOVE IN-REC TO TRX-RECORD
            dto.getTRX_RECORDDto().setTRX_RECORD(dto.getIN_REC());
            // PERFORM VALIDATE-DATA-000
            VALIDATE_DATA(dto);
            // MOVE IN-REC TO SORT-REC / RELEASE SORT-REC
            // !! SORT RELEASE → sortList에 add (나중에 처리)
            // sortList.add(dto.getSORT_RECDto());
        }

        /// READ IN-FILE AT END MOVE 'Y' TO WS-EOF-FLAG
        String line = IN_FILE.readLine();
        if (line == null) {
            // AT END
            dto.getWS_FLAGSDto().setWS_EOF_FLAG("Y");
        } else {
            // NOT AT END
            dto.setIN_REC(line);
        }

    }

    private void OUTPUT_PROC(PGM_PHASE1Dto dto) {
        // MOVE 'N' TO WS-SORT-EOF-FLAG
        dto.getWS_FLAGSDto().setWS_SORT_EOF_FLAG("N");

        // RETURN SORT-FILE
        // !! SORT RETURN → sortList에서 iterator로 대체 (나중에 처리)
            //  현재는 sortList가 비어있으면 EOF로 처리
        if (dto.getSortList() == null || dto.getSortList().isEmpty()) { // 정렬된 리스트가 비어있는가
            // AT END
            dto.getWS_FLAGSDto().setWS_SORT_EOF_FLAG("Y");
        } else {
            // NOT AT END
            continue;
        }

        // PERFORM OUTPUT-PROC-LOOP-000 UNTIL WS-SORT-EOF
        while (!dto.getWS_FLAGSDto().getWS_SORT_EOF_FLAG().equals(dto.getWS_FLAGSDto().SORT_EOF_FLAG)) {
            OUTPUT_PROC_LOOP(dto);
        }
    
    
    }

    private void OUTPUT_PROC_LOOP(PGM_PHASE1Dto dto) {

        // MOVE SORT-REC TO OUT-REC
        // !! SORT RETURN → sortList에서 순서대로 꺼내기 (나중에 처리)
        // dto.setOUT_REC(dto.getSortList().get(idx).getSR_HEAD()
        //              + dto.getSortList().get(idx).getSR_INST_CD()
        //              + dto.getSortList().get(idx).getSR_BODY());

        // WRITE OUT-REC
        try {
            OUT_FILE.write(dto.getOUT_REC());
            OUT_FILE.newLine();
        } catch (IOException e) {
            // COBOL 원본에 없는 처리
            // dto.getERR_LOG_AREADto().setERR_DESCRIPTION("OUTPUT FILE WRITE ERROR");
            // ERROR_LOG(dto);
        }

        // ADD 1 TO WS-CALC-CNT
        dto.getWS_CALC_TOTALSDto().setWS_CALC_CNT(
            dto.getWS_CALC_TOTALSDto().getWS_CALC_CNT() + 1
        );

        // COMPUTE WS-MOD-WORK = FUNCTION MOD(WS-CALC-CNT, WS-COMMIT-LIMIT)
        dto.getWS_WORK_AREASDto_1().setWS_MOD_WORK(
        dto.getWS_CALC_TOTALSDto().getWS_CALC_CNT() % dto.getWS_COMMIT_LIMIT()
        );

        // IF WS-MOD-WORK = 0
        //     PERFORM PROGRESS-LOG-000
        if (dto.getWS_WORK_AREASDto_1().getWS_MOD_WORK() == 0) {
        PROGRESS_LOG(dto);
        }

            // RETURN SORT-FILE
            //     AT END     MOVE 'Y' TO WS-SORT-EOF-FLAG
            //     NOT AT END CONTINUE
            //END-RETURN.
            // !! SORT RETURN → sortList에서 다음 요소 꺼내기 (나중에 처리)
            // !! 더 꺼낼 요소가 없으면 EOF로 처리
            // if (더 이상 요소 없음) {
            //     dto.getWS_FLAGSDto().setWS_SORT_EOF_FLAG("Y");
            // }

    }

    private void PROCESS_HEADER(PGM_PHASE1Dto dto) {
        // MOVE IN-REC TO OUT-REC
        dto.setOUT_REC(dto.getIN_REC());

        // WRITE OUT-REC
        try {
            OUT_FILE.write(dto.getOUT_REC());
            OUT_FILE.newLine();
        } catch (IOException e) {
            // dto.getERR_LOG_AREADto().setERR_DESCRIPTION("HEADER WRITE ERROR");
            // ERROR_LOG(dto);
        }

        // MOVE HDR-CREATE-DATE TO WS-HEADER-DATE
        dto.setWS_HEADER_DATE(
            dto.getFILE_CONTROL_RECDto().getHDR_CREATE_DATE()
        );

        // DISPLAY ' > HEADER  RECORD DETECTED: ' WS-HEADER-DATE
        log.info(" > HEADER  RECORD DETECTED: " + dto.getWS_HEADER_DATE());

    }

    private void PROCESS_TRAILER(PGM_PHASE1Dto dto) {
        // MOVE IN-REC TO OUT-REC
        dto.setOUT_REC(dto.getIN_REC());

        // WRITE OUT-REC
        try {
            OUT_FILE.write(dto.getOUT_REC());
            OUT_FILE.newLine();
        } catch (IOException e) {
            // dto.getERR_LOG_AREADto().setERR_DESCRIPTION("TRAILER WRITE ERROR");
            // ERROR_LOG(dto);
        }

        // MOVE TRL-TOT-CNT TO WS-TRAILER-COUNT
        dto.setWS_TRAILER_COUNT(
            dto.getFILE_CONTROL_RECDto().getTRL_TOT_CNT()
        );

        // DISPLAY ' > TRAILER RECORD DETECTED: ' WS-TRAILER-COUNT
        log.info(" > TRAILER RECORD DETECTED: " + dto.getWS_TRAILER_COUNT());
    }

    private void VALIDATE_DATA(PGM_PHASE1Dto dto) {
        // SET WS-VALID TO TRUE
        //!! getWS_FLAGSDto에 기존거 추가 해야함(PHAE1 관련 변수 다 없어짐)
        dto.getWS_FLAGSDto().setWS_VALID_FLAG(dto.getWS_FLAGSDto().WS_VALID);

        // MOVE IN-REC TO TRX-RECORD
        dto.getTRX_RECORDDto().setTRX_RECORD(dto.getIN_REC());


    }

}
