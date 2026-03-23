package com.KSInfo.batch;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import com.KSInfo.batch.dao.Phase3Dao;

import java.util.HashMap;
import java.util.Map;

@SpringBootApplication
public class TestApplication {

    public static void main(String[] args) {
        ApplicationContext ctx = SpringApplication.run(TestApplication.class, args);

        Phase3Dao phase3Dao = ctx.getBean(Phase3Dao.class);

        Map<String, Object> param = new HashMap<>();
        param.put("DTL-SETTLE-DATE", "20260313");

        int result = phase3Dao.delete_01(param);

        if (result > 0) {
            System.out.println("DELETE Success: " + result);
        } else {
            System.out.println("Nothing to delete");
        }
    }
}