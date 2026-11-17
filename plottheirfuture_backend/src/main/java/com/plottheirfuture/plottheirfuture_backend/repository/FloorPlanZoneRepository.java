package com.plottheirfuture.plottheirfuture_backend.repository;

import com.plottheirfuture.plottheirfuture_backend.entity.FloorPlanZone;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FloorPlanZoneRepository extends JpaRepository<FloorPlanZone, Long> {

    List<FloorPlanZone> findByWeddingId(Long weddingId);

    @Modifying
    @Query("UPDATE FloorPlanZone z SET z.fundedSft = z.fundedSft + :sft WHERE z.id = :id")
    int incrementFundedSft(@Param("id") Long id, @Param("sft") Integer sft);
}
