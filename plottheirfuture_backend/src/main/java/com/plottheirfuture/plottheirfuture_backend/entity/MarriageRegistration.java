package com.plottheirfuture.plottheirfuture_backend.entity;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "marriage_registrations", indexes = {
        @Index(name = "idx_marr_user", columnList = "user_id"),
        @Index(name = "idx_marr_status", columnList = "status"),
        @Index(name = "idx_marr_ref", columnList = "reference_number"),
        @Index(name = "idx_marr_slug", columnList = "slug")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MarriageRegistration {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "reference_number", unique = true, nullable = false)
    private String referenceNumber;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    // Bride details
    @Column(name = "bride_name", nullable = false)
    private String brideName;

    @Column(name = "bride_mobile_number", nullable = false)
    private String brideMobileNumber;

    @Column(name = "bride_email")
    private String brideEmail;

    @Column(name = "bride_occupation")
    private String brideOccupation;

    // Groom details
    @Column(name = "groom_name", nullable = false)
    private String groomName;

    @Column(name = "groom_mobile_number", nullable = false)
    private String groomMobileNumber;

    @Column(name = "groom_email")
    private String groomEmail;

    @Column(name = "groom_occupation")
    private String groomOccupation;

    @Column(name = "primary_contact_number", nullable = false)
    private String primaryContactNumber;

    @Column(name = "secondary_contact_number")
    private String secondaryContactNumber;

    @Column(name = "wedding_date", nullable = false)
    private LocalDate weddingDate;

    @Column(name = "city", nullable = false)
    private String city;

    @Column(name = "couple_story", length = 4000)
    private String coupleStory;

    @Column(name = "cover_image_url")
    private String coverImageUrl;

    @Column(name = "wedding_card_url", nullable = false)
    private String weddingCardUrl;

    @Column(name = "wedding_card_thumbnail_url")
    private String weddingCardThumbnailUrl;

    @Column(name = "target_bhk")
    private String targetBhk;

    @Column(name = "preferred_area")
    private String preferredArea;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    @Builder.Default
    private MarriageRegistrationStatus status = MarriageRegistrationStatus.PENDING_ADMIN_APPROVAL;

    @Column(name = "rejection_reason", length = 1000)
    private String rejectionReason;

    @Column(name = "submitted_at")
    @Builder.Default
    private LocalDateTime submittedAt = LocalDateTime.now();

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(name = "approved_by_admin_id")
    private Long approvedByAdminId;

    @Column(name = "admin_notes", length = 1000)
    private String adminNotes;

    // Assigned flat details (by Admin)
    @Column(name = "slug")
    private String slug;

    @Column(name = "wedding_id")
    private Long weddingId;

    @Column(name = "builder_name")
    private String builderName;

    @Column(name = "project_name")
    private String projectName;

    @Column(name = "tower")
    private String tower;

    @Column(name = "unit_number")
    private String unitNumber;

    @Column(name = "configuration")
    private String configuration;

    @Column(name = "target_sft")
    private Integer targetSft;

    @Column(name = "rate_sft")
    private Double rateSft;

    @Column(name = "builder_rera_id")
    private String builderReraId;

    @Column(name = "rera_project_url")
    private String reraProjectUrl;

    @Column(name = "escrow_bank_name")
    private String escrowBankName;

    @Column(name = "escrow_branch_name")
    private String escrowBranchName;

    @Column(name = "escrow_account_holder")
    private String escrowAccountHolder;

    @Column(name = "escrow_account_number")
    private String escrowAccountNumber;

    @Column(name = "escrow_ifsc_code")
    private String escrowIfscCode;

    @Column(name = "escrow_upi_vpa")
    private String escrowUpiVpa;

    @Column(name = "floor_plan_template")
    private String floorPlanTemplate;

    @Column(name = "video_stream_url")
    private String videoStreamUrl;

    @OneToMany(mappedBy = "marriageRegistration", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<MarriageCeremony> ceremonies = new ArrayList<>();
}

