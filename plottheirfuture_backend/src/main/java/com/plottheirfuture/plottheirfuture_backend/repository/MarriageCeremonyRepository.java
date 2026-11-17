package com.plottheirfuture.plottheirfuture_backend.repository;

import com.plottheirfuture.plottheirfuture_backend.entity.MarriageCeremony;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MarriageCeremonyRepository extends JpaRepository<MarriageCeremony, Long> {

    List<MarriageCeremony> findByMarriageRegistrationIdOrderByEventDateAscStartTimeAsc(Long registrationId);
}

