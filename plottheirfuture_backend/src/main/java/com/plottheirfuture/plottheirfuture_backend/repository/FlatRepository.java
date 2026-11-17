package com.plottheirfuture.plottheirfuture_backend.repository;

import com.plottheirfuture.plottheirfuture_backend.entity.Flat;
import com.plottheirfuture.plottheirfuture_backend.entity.FlatStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FlatRepository extends JpaRepository<Flat, Long> {

    Optional<Flat> findByFlatId(String flatId);

    List<Flat> findByStatus(FlatStatus status);

    Optional<Flat> findByAssignedWeddingId(Long weddingId);

    Optional<Flat> findByAssignedWeddingSlug(String slug);

    long countByStatus(FlatStatus status);

    @Query("SELECT f FROM Flat f WHERE " +
           "(:status IS NULL OR f.status = :status) AND " +
           "(:query IS NULL OR LOWER(f.name) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(f.flatId) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(f.location) LIKE LOWER(CONCAT('%', :query, '%')))")
    Page<Flat> searchFlats(@Param("status") FlatStatus status,
                           @Param("query") String query,
                           Pageable pageable);
}
