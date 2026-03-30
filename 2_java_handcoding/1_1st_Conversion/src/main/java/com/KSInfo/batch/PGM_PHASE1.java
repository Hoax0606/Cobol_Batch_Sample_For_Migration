package com.KSInfo.batch;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;


import com.KSInfo.batch.dto.PGM_PHASE1Dto;
import com.KSInfo.batch.dto.PGM_BLOGSVRDto;
import com.KSInfo.batch.dto.SORT_RECDto;

import lombok.extern.slf4j.Slf4j;

@Slf4j
public class PGM_PHASE1 {

    @Autowired
    private PGM_BLOGSVR PGM_BLOGSVR;
    @Autowired
    private PGM_BLOGSVRDto PGM_BLOGSVRDto;

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
        dto.getWS_FLAGSDto_1().setWS_EOF_FLAG("N");
        // READ IN-FILE AT END MOVE 'Y' TO WS-EOF-FLAG
            //BufferedReader.readLine()은 IOException을 throws하도록 선언되어 있어서, Java 컴파일러가 반드시 try-catch 또는 throws 선언을 요구합니다.
         try {
            String line = IN_FILE.readLine();
            if (line == null) { // 파일 끝에 도달 했는가
                dto.getWS_FLAGSDto_1().setWS_EOF_FLAG("Y");
            } else {
                dto.setIN_REC(line);
            }

         }catch (IOException e){
            // COBOL 원본에 없는 처리(클로드가 임의로 작성해준것 - 코볼 소스에는 없음)
            // dto.getERR_LOG_AREADto().setERR_DESCRIPTION("INPUT FILE READ ERROR");
            // ERROR_LOG(dto);
            // dto.getWS_FLAGSDto_1().setWS_EOF_FLAG("Y");

         }

        while (!dto.getWS_FLAGSDto_1().getWS_EOF_FLAG().equals(dto.getWS_FLAGSDto_1().WS_EOF)) {
        INPUT_PROC_LOOP(dto);
    }
    
    }
    
    private void INPUT_PROC_LOOP(PGM_PHASE1Dto dto) {
        dto.getFILE_CONTROL_RECDto().setFILE_CONTROL_REC(dto.getIN_REC());
        
        if (dto.getFILE_CONTROL_RECDto().checkIS_HEADER()) {
            PROCESS_HEADER(dto);
        } else if (dto.getFILE_CONTROL_RECDto().checkIS_TRAILER()) {
            PROCESS_TRAILER(dto);
        } else if (dto.getFILE_CONTROL_RECDto().checkIS_DATA()) {
            dto.getTRX_RECORDDto().setTRX_RECORD(dto.getIN_REC());
            VALIDATE_DATA(dto);
            // !! 나중에 다시보기 
            // MOVE IN-REC TO SORT-REC / RELEASE SORT-REC
            // SORT RELEASE → sortList에 add (나중에 처리)
            // sortList.add(dto.getSORT_RECDto());
        }

        String line = IN_FILE.readLine();
        if (line == null) {
            dto.getWS_FLAGSDto_1().setWS_EOF_FLAG("Y");
        } else {
            dto.setIN_REC(line);
        }
    }

    private void OUTPUT_PROC(PGM_PHASE1Dto dto) {
        dto.getWS_FLAGSDto_1().setWS_SORT_EOF_FLAG("N");

        // !! 나중에 다시보기
        // RETURN SORT-FILE
        //SORT RETURN → sortList에서 iterator로 대체 (나중에 처리)
            //  현재는 sortList가 비어있으면 EOF로 처리
        if (dto.getSortList() == null || dto.getSortList().isEmpty()) { // 정렬된 리스트가 비어있는가
            dto.getWS_FLAGSDto_1().setWS_SORT_EOF_FLAG("Y");
        } else {
            continue;
        }

        while (!dto.getWS_FLAGSDto_1().getWS_SORT_EOF_FLAG().equals(dto.getWS_FLAGSDto_1().SORT_EOF_FLAG)) {
            OUTPUT_PROC_LOOP(dto);
        }
    }

    private void OUTPUT_PROC_LOOP(PGM_PHASE1Dto dto) {

        //!! 나중에 다시보기
        // MOVE SORT-REC TO OUT-REC
        // SORT RETURN → sortList에서 순서대로 꺼내기 (나중에 처리)
        // dto.setOUT_REC(dto.getSortList().get(idx).getSR_HEAD()
        //              + dto.getSortList().get(idx).getSR_INST_CD()
        //              + dto.getSortList().get(idx).getSR_BODY());

        try {
            OUT_FILE.write(dto.getOUT_REC());
            OUT_FILE.newLine();
        } catch (IOException e) {
            // COBOL 원본에 없는 처리
            // dto.getERR_LOG_AREADto().setERR_DESCRIPTION("OUTPUT FILE WRITE ERROR");
            // ERROR_LOG(dto);
        }

        dto.getWS_CALC_TOTALSDto().setWS_CALC_CNT(
            dto.getWS_CALC_TOTALSDto().getWS_CALC_CNT() + 1
        );

        dto.getWS_WORK_AREASDto_1().setWS_MOD_WORK(
        dto.getWS_CALC_TOTALSDto().getWS_CALC_CNT() % dto.getWS_COMMIT_LIMIT()
        );

        if (dto.getWS_WORK_AREASDto_1().getWS_MOD_WORK() == 0) {
        PROGRESS_LOG(dto);
        }

            //!! 나중에 다시보기
            // RETURN SORT-FILE
            //     AT END     MOVE 'Y' TO WS-SORT-EOF-FLAG
            //     NOT AT END CONTINUE
            // END-RETURN.
            // SORT RETURN → sortList에서 다음 요소 꺼내기 (나중에 처리)
            // 더 꺼낼 요소가 없으면 EOF로 처리
            // if (더 이상 요소 없음) {
            //     dto.getWS_FLAGSDto_1().setWS_SORT_EOF_FLAG("Y");
            // }

    }

    private void PROCESS_HEADER(PGM_PHASE1Dto dto) {
        dto.setOUT_REC(dto.getIN_REC());

        try {
            OUT_FILE.write(dto.getOUT_REC());
            OUT_FILE.newLine();
        } catch (IOException e) {
            // dto.getERR_LOG_AREADto().setERR_DESCRIPTION("HEADER WRITE ERROR");
            // ERROR_LOG(dto);
        }

        dto.setWS_HEADER_DATE(
            dto.getFILE_CONTROL_RECDto().getHDR_CREATE_DATE()
        );

        log.info(" > HEADER  RECORD DETECTED: " + dto.getWS_HEADER_DATE());
    }

    private void PROCESS_TRAILER(PGM_PHASE1Dto dto) {
        dto.setOUT_REC(dto.getIN_REC());

        try {
            OUT_FILE.write(dto.getOUT_REC());
            OUT_FILE.newLine();
        } catch (IOException e) {
            // dto.getERR_LOG_AREADto().setERR_DESCRIPTION("TRAILER WRITE ERROR");
            // ERROR_LOG(dto);
        }

        dto.setWS_TRAILER_COUNT(
            dto.getFILE_CONTROL_RECDto().getTRL_TOT_CNT()
        );

        log.info(" > TRAILER RECORD DETECTED: " + dto.getWS_TRAILER_COUNT());
    }

    private void VALIDATE_DATA(PGM_PHASE1Dto dto) {
        // SET WS-VALID TO TRUE
        //!! getWS_FLAGSDto_1에 기존거 추가 해야함(PHAE1 관련 변수 다 없어짐)
        dto.getWS_FLAGSDto_1().setWS_VALID_FLAG(dto.getWS_FLAGSDto_1().WS_VALID);

        dto.getTRX_RECORDDto().setTRX_RECORD(dto.getIN_REC());
        dto.setWS_INSPECT_CNT(0);

        String trxRecord = dto.getTRX_RECORDDto().getTRX_RECORD();
        for (char c : trxRecord.toCharArray()) {
        if (c == '\t' || c == '\r' || c == '\n') {
            dto.setWS_INSPECT_CNT(dto.getWS_INSPECT_CNT() + 1);
            }
        }
        
        if (dto.getWS_INSPECT_CNT() > 0) {
            VALIDATE_ERR_CTRL_CHAR(dto);  
        } else {
            dto.getTRX_RECORDDto().setTRX_RECORD("");
            dto.getWS_CALC_TOTALSDto().setWS_TRX_COUNT(0);
            String[] tokens = dto.getIN_REC().split(" ");
            dto.getWS_CALC_TOTALSDto().setWS_TRX_COUNT(tokens.length);

            // ON OVERFLOW → 필드가 7개를 초과하는 경우
            if (tokens.length > 7) {
                VALIDATE_ERR_OVERFLOW(dto);
            } else {
                // INTO → 파싱 결과를 각 필드에 세팅 , NOT ON OVERFLOW -> else
                if (tokens.length >= 1) dto.getTRX_RECORDDto().setTRX_HEADER(tokens[0]);
                if (tokens.length >= 2) dto.getTRX_RECORDDto().setTRX_DATE(tokens[1]);
                if (tokens.length >= 3) {
                    dto.getTRX_RECORDDto().setTRX_SEQ(tokens[2]);
                    // COUNT IN WS-CNT-SEQ → TRX-SEQ 세팅 직후 길이 세팅
                    dto.getWS_WORK_AREASDto_1().setWS_CNT_SEQ(dto.getTRX_RECORDDto().getTRX_SEQ().length());
                }                
                if (tokens.length >= 4) dto.getTRX_RECORDDto().setINST_CD(tokens[3]);
                if (tokens.length >= 5) {
                    dto.getTRX_RECORDDto().setACC_NO(tokens[4]);
                    // COUNT IN WS-CNT-ACC → ACC-NO 세팅 직후 길이 세팅
                    dto.getWS_WORK_AREASDto_1().setWS_CNT_ACC(dto.getTRX_RECORDDto().getACC_NO().length());
                }
                if (tokens.length >= 6) dto.getTRX_RECORDDto().setTRX_TYPE(tokens[5]);
                if (tokens.length >= 7) dto.setWS_LOG_TRX_AMT(tokens[6]);

                    if (dto.getWS_CALC_TOTALSDto().getWS_TRX_COUNT() != 7) {
                        VALIDATE_ERR_FIELD(dto);
                    } else if (!dto.getTRX_RECORDDto().getTRX_SEQ().matches("[0-9]+")
                            || dto.getWS_WORK_AREASDto_1().getWS_CNT_SEQ() != 10) {
                        VALIDATE_ERR_SEQ(dto);
                    } else if (dto.getTRX_RECORDDto().getINST_CD().trim().isEmpty()) {
                        VALIDATE_ERR_INST(dto);
                    } else if (dto.getTRX_RECORDDto().getACC_NO().trim().isEmpty()
                            || dto.getWS_WORK_AREASDto_1().getWS_CNT_ACC() != 15) {
                        VALIDATE_ERR_ACC(dto);
                    } else if (!dto.getTRX_RECORDDto().getTRX_TYPE().equals("I")
                            && !dto.getTRX_RECORDDto().getTRX_TYPE().equals("O")) {
                        VALIDATE_ERR_TYPE(dto);
                    } else if (!dto.getWS_LOG_TRX_AMT().matches("[0-9]+")) {
                        VALIDATE_ERR_AMT(dto);
                    } else {            
                        if (dto.getTRX_RECORDDto().getTRX_TYPE().equals("I")) {
                            dto.getTRX_RECORDDto().setTRX_AMT(dto.getWS_LOG_TRX_AMT());
                        
                            dto.setWS_CALC_AMT(
                                dto.getWS_CALC_AMT().add(
                                    new BigDecimal(dto.getWS_LOG_TRX_AMT().trim())
                                )
                            );
                        } else {
                            dto.getTRX_RECORDDto().setTRX_AMT(dto.getWS_LOG_TRX_AMT());
                            dto.setWS_CALC_AMT(
                                dto.getWS_CALC_AMT().subtract(
                                    new BigDecimal(dto.getWS_LOG_TRX_AMT().trim())
                            )
                        );
                    }
                }
            }
        }
    }    

    private void VALIDATE_ERR_FIELD(PGM_PHASE1Dto dto) {

        dto.getWS_FLAGSDto_1().setWS_VALID_FLAG(dto.getWS_FLAGSDto_1().WS_INVALID);

        dto.getWS_CALC_TOTALSDto().setWS_ERR_CNT(
            dto.getWS_CALC_TOTALSDto().getWS_ERR_CNT() + 1
        );
        dto.setWS_INSPECT_CNT(dto.getWS_INSPECT_CNT() + 1);

        dto.setERR_REC(dto.getIN_REC());

        try {
            ERR_FILE.write(dto.getERR_REC());
            ERR_FILE.newLine();
        } catch (IOException e) {
            // COBOL 원본에 없는 처리
        }

        log.info(" > [" + dto.getWS_ERR_FIELD() + "] FIELD COUNT INCORRECT : ["
                + dto.getWS_INSPECT_CNT() + "]");
    }
    private void VALIDATE_ERR_AMT(PGM_PHASE1Dto dto) {

        dto.getWS_FLAGSDto_1().setWS_VALID_FLAG(dto.getWS_FLAGSDto_1().WS_INVALID);
        dto.getWS_CALC_TOTALSDto().setWS_ERR_CNT(
            dto.getWS_CALC_TOTALSDto().getWS_ERR_CNT() + 1
        );
        dto.setERR_REC(dto.getIN_REC());

        try {
            ERR_FILE.write(dto.getERR_REC());
            ERR_FILE.newLine();
        } catch (IOException e) {
            // COBOL 원본에 없는 처리
        }

        dto.setWS_LOG_BUFFER(
            " > [" + dto.getWS_ERR_CODE_AMT() + "] AMOUNT NOT NUMERIC. SEQ = ["
            + dto.getTRX_RECORDDto().getTRX_SEQ() + "] / AMOUNT = ["
            + dto.getWS_LOG_TRX_AMT() + "]"
        );
        log.info(dto.getWS_LOG_BUFFER());
        dto.setWS_LOG_PTR(1);
        dto.setWS_LOG_BUFFER("");
    }
    private void VALIDATE_ERR_SEQ(PGM_PHASE1Dto dto) {

        dto.getWS_FLAGSDto_1().setWS_VALID_FLAG(dto.getWS_FLAGSDto_1().WS_INVALID);
        dto.getWS_CALC_TOTALSDto().setWS_ERR_CNT(
            dto.getWS_CALC_TOTALSDto().getWS_ERR_CNT() + 1
        );
        dto.setERR_REC(dto.getIN_REC());

        try {
            ERR_FILE.write(dto.getERR_REC());
            ERR_FILE.newLine();
        } catch (IOException e) {
            // COBOL 원본에 없는 처리
        }
        log.info(" > [" + dto.getWS_ERR_CODE_SEQ() + "] SEQ NOT NUMERIC. SEQ = ["
                + dto.getTRX_RECORDDto().getTRX_SEQ() + "]");
    }
    private void VALIDATE_ERR_TYPE(PGM_PHASE1Dto dto) {

        dto.getWS_FLAGSDto_1().setWS_VALID_FLAG(dto.getWS_FLAGSDto_1().WS_INVALID);
        dto.getWS_CALC_TOTALSDto().setWS_ERR_CNT(
            dto.getWS_CALC_TOTALSDto().getWS_ERR_CNT() + 1
        );
        dto.setERR_REC(dto.getIN_REC());

        try {
            ERR_FILE.write(dto.getERR_REC());
            ERR_FILE.newLine();
        } catch (IOException e) {
            // COBOL 원본에 없는 처리
        }
        log.info(" > [" + dto.getWS_ERR_CODE_TYPE() + "] TYPE INVALID. SEQ = ["
                + dto.getTRX_RECORDDto().getTRX_SEQ() + "] / TYPE = ["
                + dto.getTRX_RECORDDto().getTRX_TYPE() + "]");
    }
    private void VALIDATE_ERR_INST(PGM_PHASE1Dto dto) {

        // SET WS-INVALID TO TRUE
        dto.getWS_FLAGSDto_1().setWS_VALID_FLAG(dto.getWS_FLAGSDto_1().WS_INVALID);

        // ADD 1 TO WS-ERR-CNT
        dto.getWS_CALC_TOTALSDto().setWS_ERR_CNT(
            dto.getWS_CALC_TOTALSDto().getWS_ERR_CNT() + 1
        );

        // MOVE IN-REC TO ERR-REC
        dto.setERR_REC(dto.getIN_REC());

        // WRITE ERR-REC
        try {
            ERR_FILE.write(dto.getERR_REC());
            ERR_FILE.newLine();
        } catch (IOException e) {
            // COBOL 원본에 없는 처리
        }

        // DISPLAY ' > [' WS-ERR-CODE-INST '] INSTITUTION INVALID. SEQ = [' TRX-SEQ'] / INST = [' INST-CD']'
        log.info(" > [" + dto.getWS_ERR_CODE_INST() + "] INSTITUTION INVALID."
                + "SEQ = [" + dto.getTRX_RECORDDto().getTRX_SEQ() + "] / INST = ["
                + dto.getTRX_RECORDDto().getINST_CD() + "]");
    }
    private void VALIDATE_ERR_ACC(PGM_PHASE1Dto dto) {

        // SET WS-INVALID TO TRUE
        dto.getWS_FLAGSDto_1().setWS_VALID_FLAG(dto.getWS_FLAGSDto_1().WS_INVALID);

        // ADD 1 TO WS-ERR-CNT
        dto.getWS_CALC_TOTALSDto().setWS_ERR_CNT(
            dto.getWS_CALC_TOTALSDto().getWS_ERR_CNT() + 1
        );

        // MOVE IN-REC TO ERR-REC
        dto.setERR_REC(dto.getIN_REC());

        // WRITE ERR-REC
        try {
            ERR_FILE.write(dto.getERR_REC());
            ERR_FILE.newLine();
        } catch (IOException e) {
            // COBOL 원본에 없는 처리
        }

        // DISPLAY ' > [' WS-ERR-CODE-ACC '] ACCOUNT INVALID. SEQ = [' TRX-SEQ'] / ACC = [' ACC-NO']'
        log.info(" > [" + dto.getWS_ERR_CODE_ACC() + "] ACCOUNT INVALID."
                + "SEQ = [" + dto.getTRX_RECORDDto().getTRX_SEQ() + "] / ACC = ["
                + dto.getTRX_RECORDDto().getACC_NO() + "]");
    }
    private void VALIDATE_ERR_CTRL_CHAR(PGM_PHASE1Dto dto) {

        // SET WS-INVALID TO TRUE
        dto.getWS_FLAGSDto_1().setWS_VALID_FLAG(dto.getWS_FLAGSDto_1().WS_INVALID);

        // ADD 1 TO WS-ERR-CNT
        dto.getWS_CALC_TOTALSDto().setWS_ERR_CNT(
            dto.getWS_CALC_TOTALSDto().getWS_ERR_CNT() + 1
        );

        // MOVE IN-REC TO ERR-REC
        dto.setERR_REC(dto.getIN_REC());

        // WRITE ERR-REC
        try {
            ERR_FILE.write(dto.getERR_REC());
            ERR_FILE.newLine();
        } catch (IOException e) {
            // COBOL 원본에 없는 처리
        }

        // DISPLAY ' > [' WS-ERR-CODE-CTRL '] CTRL CHAR DETECTED : [' WS-INSPECT-CNT '] CHARS'
        log.info(" > [" + dto.getWS_ERR_CODE_CTRL() + "] CTRL CHAR DETECTED : ["
                + dto.getWS_INSPECT_CNT() + "] CHARS");
    }
    private void VALIDATE_ERR_OVERFLOW(PGM_PHASE1Dto dto) {

        // SET WS-INVALID TO TRUE
        dto.getWS_FLAGSDto_1().setWS_VALID_FLAG(dto.getWS_FLAGSDto_1().WS_INVALID);

        // ADD 1 TO WS-ERR-CNT
        dto.getWS_CALC_TOTALSDto().setWS_ERR_CNT(
            dto.getWS_CALC_TOTALSDto().getWS_ERR_CNT() + 1
        );

        // MOVE IN-REC TO ERR-REC
        dto.setERR_REC(dto.getIN_REC());

        // WRITE ERR-REC
        try {
            ERR_FILE.write(dto.getERR_REC());
            ERR_FILE.newLine();
        } catch (IOException e) {
            // COBOL 원본에 없는 처리
        }

        // DISPLAY ' > [' WS-ERR-CODE-OVF '] UNSTRING OVERFLOW DETECTED'
        log.info(" > [" + dto.getWS_ERR_CODE_OVF() + "] UNSTRING OVERFLOW DETECTED");
    }

    private void PROGRESS_LOG(PGM_PHASE1Dto dto) {

        // DISPLAY ' > ... ' WS-CALC-CNT ' DATA RECORDS PROCESSED... <'
        log.info(" > ... " + dto.getWS_CALC_TOTALSDto().getWS_CALC_CNT()
                + " DATA RECORDS PROCESSED... <");
    }

    private void CHECK_COUNT(PGM_PHASE1Dto dto) {
        log.info(" [DEBUG] "
                + dto.getWS_CALC_TOTALSDto().getWS_CALC_CNT()
                + " + "
                + dto.getWS_CALC_TOTALSDto().getWS_ERR_CNT()
                + " = "
                + dto.getFILE_CONTROL_RECDto().getTRL_TOT_CNT());

        log.info(" [DEBUG] "
                + dto.getWS_CALC_AMT()
                + " = "
                + new BigDecimal(dto.getFILE_CONTROL_RECDto().getTRL_TOT_AMT().trim()));
        /* !! redefines 작업 후 진행 !! ----------------------------
            // IF WS-CALC-CNT + WS-ERR-CNT NOT = TRL-TOT-CNT
            // OR WS-CALC-AMT NOT = FUNCTION NUMVAL(TRL-TOT-AMT)
        if ((dto.getWS_CALC_TOTALSDto().getWS_CALC_CNT()
            + dto.getWS_CALC_TOTALSDto().getWS_ERR_CNT())
                != dto.getFILE_CONTROL_RECDto().getTRL_TOT_CNT()
            || dto.getWS_CALC_AMT().compareTo(
                BigDecimal.valueOf(dto.getFILE_CONTROL_RECDto().getTRL_TOT_AMT())) != 0) {
             
        
        */
       if(pass){
            dto.getERR_LOG_AREADto().setERR_DESCRIPTION("TRAILER AMOUNT/COUNT MISMATCH");
            ERROR_LOG(dto);
            dto.getSYS_COMMON_AREADto().setSYS_RET_CODE(
                dto.getSYS_COMMON_AREADto().BATCH_ERROR
            );
        } else {
            log.info(" > TRAILER VALIDATION SUCCESS!");
        }
    }

    private void FINALIZE(PGM_PHASE1Dto dto) {
        // CLOSE IN-FILE OUT-FILE ERR-FILE
        /*파일이 null → 파일 자체가 열리지 않은 경우 (현재 null 체크로 처리됨)
        파일에 데이터가 없음 → 파일은 열렸지만 에러 레코드가 없는 경우 */
        try {
            if (IN_FILE  != null) IN_FILE.close();
        } catch (IOException e) {
            // COBOL 원본에 없는 처리
        }
        try {
            if (OUT_FILE != null) OUT_FILE.close();
        } catch (IOException e) {
            // COBOL 원본에 없는 처리
        }
        try {
            if (ERR_FILE != null) ERR_FILE.close();
        } catch (IOException e) {
            // COBOL 원본에 없는 처리
        }


        log.info(" > ========= PGM-PHASE1 RESULT =========");
        log.info(" > VALID COUNT : " + dto.getWS_CALC_TOTALSDto().getWS_CALC_CNT());
        log.info(" > VALID AMOUNT: " + dto.getWS_CALC_AMT());
        log.info(" > ERROR COUNT : " + dto.getWS_CALC_TOTALSDto().getWS_ERR_CNT());
        log.info(" > =====================================");

        BLOGSVR_END(dto);
    }
    private void ERROR_LOG(PGM_PHASE1Dto dto) {
        dto.getERR_LOG_AREADto().setERR_PGM_ID(dto.getWS_PROG_NAME());
        dto.getERR_LOG_AREADto().setERR_SEVERITY(dto.getERR_LOG_AREADto().ERR_FATAL);
        log.info("*** SYSTEM ERROR OCCURRED ***");
        log.info("PGM: " + dto.getERR_LOG_AREADto().getERR_PGM_ID()
                + " | MSG: " + dto.getERR_LOG_AREADto().getERR_DESCRIPTION());
    }
    private void BLOGSVR_START(PGM_PHASE1Dto dto) {

        dto.getDCL_TB_BATCH_LOGDto().setBLG_PGM_ID(dto.getWS_PROG_NAME());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_BIZ_DATE(dto.getSYS_COMMON_AREADto().getSYS_BIZ_DATE());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_REMARK("PHASE1 STARTED");
        dto.getDCL_TB_BATCH_LOGDto().setBLG_ACTION("START");
        // CALL 'PGM-BLOGSVR' USING DCL-TB-BATCH-LOG
        PGM_BLOGSVR.MAIN(PGM_BLOGSVRDto);

        if (dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE() != 0) {
            log.info("> [WARN] BLOGSVR START FAILED. RC=" + dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE());
        } else {
            // CONTINUE
        }
    }
    private void BLOGSVR_END(PGM_PHASE1Dto dto) {

        dto.getDCL_TB_BATCH_LOGDto().setBLG_PROC_CNT(dto.getWS_CALC_TOTALSDto().getWS_CALC_CNT());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_ERR_CNT(dto.getWS_CALC_TOTALSDto().getWS_ERR_CNT());
        dto.getDCL_TB_BATCH_LOGDto().setBLG_ACTION("END  ");
        if (dto.getWS_CALC_TOTALSDto().getWS_ERR_CNT() > 0) {
            dto.getDCL_TB_BATCH_LOGDto().setBLG_STAT("E");
            dto.getDCL_TB_BATCH_LOGDto().setBLG_REMARK("PHASE1 COMPLETED WITH ERRORS");
        } else {
            dto.getDCL_TB_BATCH_LOGDto().setBLG_STAT("S");
            dto.getDCL_TB_BATCH_LOGDto().setBLG_REMARK("PHASE1 COMPLETED SUCCESSFULLY");
        }

        PGM_BLOGSVR.MAIN(PGM_BLOGSVRDto);

        if (dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE() != 0) {
            log.info("> [WARN] BLOGSVR END FAILED. RC="
                    + dto.getDCL_TB_BATCH_LOGDto().getBLG_RETURN_CODE());
        } else {
            // CONTINUE
        }
    }

}
