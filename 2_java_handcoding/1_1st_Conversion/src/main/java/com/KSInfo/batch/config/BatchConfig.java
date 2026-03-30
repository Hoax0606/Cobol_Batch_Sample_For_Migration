package com.KSInfo.batch.config;

import org.springframework.batch.core.Job;
import org.springframework.batch.core.Step;
import org.springframework.batch.core.configuration.annotation.EnableBatchProcessing;
import org.springframework.batch.core.configuration.annotation.JobBuilderFactory;
import org.springframework.batch.core.configuration.annotation.StepBuilderFactory;
import org.springframework.batch.repeat.RepeatStatus;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.KSInfo.batch.pgm.PGM_PHASE1;
import com.KSInfo.batch.pgm.PGM_PHASE2;
import com.KSInfo.batch.pgm.PGM_PHASE3;
import com.KSInfo.batch.pgm.PGM_PHASE4;
import com.KSInfo.batch.dto.PGM_PHASE1Dto;
import com.KSInfo.batch.dto.PGM_PHASE2Dto;
import com.KSInfo.batch.dto.PGM_PHASE3Dto;
import com.KSInfo.batch.dto.PGM_PHASE4Dto;

@Configuration
@EnableBatchProcessing
public class BatchConfig {

    // 4.x 방식 - JobBuilderFactory, StepBuilderFactory 사용
    @Autowired private JobBuilderFactory  jobBuilderFactory;
    @Autowired private StepBuilderFactory stepBuilderFactory;

    @Autowired private PGM_PHASE1 PGM_PHASE1;
    @Autowired private PGM_PHASE2 PGM_PHASE2;
    @Autowired private PGM_PHASE3 PGM_PHASE3;
    @Autowired private PGM_PHASE4 PGM_PHASE4;

    @Bean
    public Job phaseJob() {
        return jobBuilderFactory.get("phaseJob")
                .start(pgmPhase1())
                .next(pgmPhase2())
                .next(pgmPhase3())
                .next(pgmPhase4())
                .build();
    }

    @Bean
    public Step pgmPhase1() {
        return stepBuilderFactory.get("pgmPhase1")
                .tasklet((contribution, chunkContext) -> {
                    PGM_PHASE1.MAIN(new PGM_PHASE1Dto());
                    return RepeatStatus.FINISHED;
                })
                .build();
    }

    @Bean
    public Step pgmPhase2() {
        return stepBuilderFactory.get("pgmPhase2")
                .tasklet((contribution, chunkContext) -> {
                    PGM_PHASE2.MAIN(new PGM_PHASE2Dto());
                    return RepeatStatus.FINISHED;
                })
                .build();
    }

    @Bean
    public Step pgmPhase3() {
        return stepBuilderFactory.get("pgmPhase3")
                .tasklet((contribution, chunkContext) -> {
                    PGM_PHASE3.MAIN(new PGM_PHASE3Dto());
                    return RepeatStatus.FINISHED;
                })
                .build();
    }

    @Bean
    public Step pgmPhase4() {
        return stepBuilderFactory.get("pgmPhase4")
                .tasklet((contribution, chunkContext) -> {
                    PGM_PHASE4.MAIN(new PGM_PHASE4Dto());
                    return RepeatStatus.FINISHED;
                })
                .build();
    }
}