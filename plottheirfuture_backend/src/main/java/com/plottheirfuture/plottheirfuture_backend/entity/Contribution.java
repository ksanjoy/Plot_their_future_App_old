package com.plottheirfuture.plottheirfuture_backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "contributions", indexes = {
        @Index(name = "idx_contrib_wedding_status", columnList = "wedding_id, payment_status"),
        @Index(name = "idx_contrib_txnid", columnList = "txn_id"),
        @Index(name = "idx_contrib_flat", columnList = "flat_id"),
        @Index(name = "idx_contrib_section", columnList = "section_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Contribution {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "wedding_id", nullable = false)
    private Long weddingId;

    @Column(name = "flat_id")
    private Long flatId;

    @Column(name = "section_id")
    private Long sectionId;

    @Column(name = "section_name")
    private String sectionName;

    @Column(name = "guest_name")
    private String guestName;

    @Column(name = "guest_mobile")
    private String guestMobile;

    @Column(name = "guest_email")
    private String guestEmail;

    @Column(name = "invitation_id")
    private Long invitationId;

    @Column(name = "units_sft", nullable = false)
    private Integer unitsSft;

    @Column(name = "brick_equivalent")
    @Builder.Default
    private Integer brickEquivalent = 10;

    @Column(name = "price_per_sft")
    private Double pricePerSft;

    @Column(name = "amount", nullable = false)
    private Double amount;

    @Column(name = "txn_id")
    private String txnId;

    @Column(name = "bank_ref")
    private String bankRef;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_status")
    @Builder.Default
    private PaymentStatus paymentStatus = PaymentStatus.INITIATED;

    @Column(name = "is_anonymous")
    @Builder.Default
    private Boolean isAnonymous = false;

    @Column(name = "blessing_message", length = 1000)
    private String blessingMessage;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
