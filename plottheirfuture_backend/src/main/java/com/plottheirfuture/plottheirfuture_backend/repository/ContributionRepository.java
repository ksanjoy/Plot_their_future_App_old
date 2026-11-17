package com.plottheirfuture.plottheirfuture_backend.repository;

import com.plottheirfuture.plottheirfuture_backend.entity.Contribution;
import com.plottheirfuture.plottheirfuture_backend.entity.PaymentStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ContributionRepository extends JpaRepository<Contribution, Long> {

    List<Contribution> findByWeddingId(Long weddingId);

    List<Contribution> findByWeddingIdAndPaymentStatus(Long weddingId, PaymentStatus paymentStatus);

    List<Contribution> findByFlatId(Long flatId);

    List<Contribution> findBySectionId(Long sectionId);

    @Query("SELECT c FROM Contribution c WHERE " +
           "(:weddingId IS NULL OR c.weddingId = :weddingId) AND " +
           "(:flatId IS NULL OR c.flatId = :flatId) AND " +
           "(:sectionId IS NULL OR c.sectionId = :sectionId) AND " +
           "(:paymentStatus IS NULL OR c.paymentStatus = :paymentStatus) AND " +
           "(:query IS NULL OR LOWER(c.guestName) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(c.guestMobile) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(c.txnId) LIKE LOWER(CONCAT('%', :query, '%')))")
    Page<Contribution> searchContributions(@Param("weddingId") Long weddingId,
                                           @Param("flatId") Long flatId,
                                           @Param("sectionId") Long sectionId,
                                           @Param("paymentStatus") PaymentStatus paymentStatus,
                                           @Param("query") String query,
                                           Pageable pageable);

    @Query("SELECT COALESCE(SUM(c.unitsSft), 0) FROM Contribution c WHERE c.paymentStatus = 'SUCCESS'")
    Integer sumTotalGiftedSft();

    @Query("SELECT COALESCE(SUM(c.amount), 0.0) FROM Contribution c WHERE c.paymentStatus = 'SUCCESS'")
    Double sumTotalGiftedAmount();

    @Query("SELECT COALESCE(SUM(c.brickEquivalent), 0) FROM Contribution c WHERE c.paymentStatus = 'SUCCESS'")
    Integer sumTotalBrickEquivalent();
}
