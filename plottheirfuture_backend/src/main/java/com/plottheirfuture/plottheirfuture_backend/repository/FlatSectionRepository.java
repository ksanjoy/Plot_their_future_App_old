package com.plottheirfuture.plottheirfuture_backend.repository;

import com.plottheirfuture.plottheirfuture_backend.entity.FlatSection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FlatSectionRepository extends JpaRepository<FlatSection, Long> {

    List<FlatSection> findByFlatIdOrderByIdAsc(Long flatId);

    @Query("SELECT COALESCE(SUM(s.areaSft), 0) FROM FlatSection s WHERE s.flatId = :flatId")
    Integer sumAreaSftByFlatId(@Param("flatId") Long flatId);

    @Query("SELECT COALESCE(SUM(s.giftedSft), 0) FROM FlatSection s WHERE s.flatId = :flatId")
    Integer sumGiftedSftByFlatId(@Param("flatId") Long flatId);

    void deleteByFlatId(Long flatId);
}
