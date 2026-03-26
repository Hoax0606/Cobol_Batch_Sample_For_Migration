package com.KSInfo.batch.dto;

import lombok.Data;

@Data
public class NETTING_TABLEDto {
    private NET_ENTRYDto[] NET_ENTRYDto = new NET_ENTRYDto[1001];
    private int NET_IDX = 0;





    public NETTING_TABLEDto() {
        for (int i = 1; i <= 1000; i++) {
            NET_ENTRYDto[i] = new NET_ENTRYDto();
        }
    }
}
