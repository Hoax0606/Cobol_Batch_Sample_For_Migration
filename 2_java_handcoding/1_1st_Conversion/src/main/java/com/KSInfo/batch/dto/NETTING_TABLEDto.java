package com.KSInfo.batch.dto;

import lombok.Data;
import java.util.List;
import java.util.ArrayList;

@Data
public class NETTING_TABLEDto {
    private List<NET_ENTRYDto> NET_ENTRYDto = new ArrayList<>(1000);
    private int NET_IDX = 0;
}
