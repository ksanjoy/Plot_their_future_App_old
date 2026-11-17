package com.plottheirfuture.plottheirfuture_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EscrowBankDto {

    private String bankName;

    private String branchName;

    private String accountHolder;

    private String accountNumber;

    private String ifscCode;

    private String upiVpa;
}

