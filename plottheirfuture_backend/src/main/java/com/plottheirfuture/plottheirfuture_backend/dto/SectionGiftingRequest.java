package com.plottheirfuture.plottheirfuture_backend.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SectionGiftingRequest {

    @NotNull(message = "Section ID is required")
    private Long sectionId;

    @NotNull(message = "Gift quantity in Sq. Ft. is required")
    @Min(value = 1, message = "Gift quantity must be at least 1 Sq. Ft.")
    private Integer unitsSft;

    @NotBlank(message = "Guest name is required")
    private String guestName;

    @NotBlank(message = "Guest mobile number is required")
    private String guestMobile;

    private String guestEmail;
    private String blessingMessage;
    private Boolean isAnonymous;
    private String paymentReference;
}
