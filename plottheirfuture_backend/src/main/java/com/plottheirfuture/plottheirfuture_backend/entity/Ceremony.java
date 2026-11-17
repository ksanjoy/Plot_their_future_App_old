package com.plottheirfuture.plottheirfuture_backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;

@Entity
@Table(name = "ceremonies", indexes = {
        @Index(name = "idx_ceremony_wedding", columnList = "wedding_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Ceremony {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "wedding_id", nullable = false)
    private Long weddingId;

    @Column(name = "ceremony_type")
    private String ceremonyType;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "event_date")
    private LocalDate eventDate;

    @Column(name = "start_time")
    private LocalTime startTime;

    @Column(name = "end_time")
    private LocalTime endTime;

    @Column(name = "venue_name")
    private String venueName;

    @Column(name = "venue_address", length = 1000)
    private String venueAddress;

    @Column(name = "venue_map_url", length = 1000)
    private String venueMapUrl;

    @Column(name = "ceremony_image_url", length = 1000)
    private String ceremonyImageUrl;

    @Column(name = "dress_code", length = 500)
    private String dressCode;

    @Column(name = "notes", length = 1000)
    private String notes;
}
