package com.plottheirfuture.plottheirfuture_backend.repository;

import com.plottheirfuture.plottheirfuture_backend.entity.MarriageRegistration;
import com.plottheirfuture.plottheirfuture_backend.entity.MarriageRegistrationStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MarriageRegistrationRepository extends JpaRepository<MarriageRegistration, Long> {

    List<MarriageRegistration> findByUserIdOrderBySubmittedAtDesc(Long userId);

    Optional<MarriageRegistration> findByReferenceNumber(String referenceNumber);

    Optional<MarriageRegistration> findBySlug(String slug);

    long countByStatus(MarriageRegistrationStatus status);

    @Query("SELECT r FROM MarriageRegistration r WHERE " +
           "(:status IS NULL OR r.status = :status) AND " +
           "(:city IS NULL OR LOWER(r.city) = LOWER(:city)) AND " +
           "(:query IS NULL OR LOWER(r.referenceNumber) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           " LOWER(r.brideName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           " LOWER(r.groomName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           " r.primaryContactNumber LIKE CONCAT('%', :query, '%'))")
    Page<MarriageRegistration> searchRegistrations(
            @Param("status") MarriageRegistrationStatus status,
            @Param("city") String city,
            @Param("query") String query,
            Pageable pageable);
}

