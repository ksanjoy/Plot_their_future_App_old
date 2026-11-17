package com.plottheirfuture.plottheirfuture_backend.service;

import com.plottheirfuture.plottheirfuture_backend.entity.Contribution;
import com.plottheirfuture.plottheirfuture_backend.entity.Flat;
import com.plottheirfuture.plottheirfuture_backend.entity.FlatSection;
import com.plottheirfuture.plottheirfuture_backend.entity.FlatStatus;
import com.plottheirfuture.plottheirfuture_backend.entity.PaymentStatus;
import com.plottheirfuture.plottheirfuture_backend.entity.Wedding;
import com.plottheirfuture.plottheirfuture_backend.repository.ContributionRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FlatRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FlatSectionRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.WeddingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AdminAnalyticsService {

    private final FlatRepository flatRepository;
    private final FlatSectionRepository flatSectionRepository;
    private final WeddingRepository weddingRepository;
    private final ContributionRepository contributionRepository;

    /**
     * Complete Admin Dashboard Analytics
     */
    public Map<String, Object> getDashboardAnalytics() {
        long totalFlats = flatRepository.count();
        long approvedFlats = flatRepository.countByStatus(FlatStatus.APPROVED);
        long pendingFlats = flatRepository.countByStatus(FlatStatus.PENDING_APPROVAL);
        long assignedFlats = flatRepository.countByStatus(FlatStatus.ASSIGNED);
        long draftFlats = flatRepository.countByStatus(FlatStatus.DRAFT);
        long totalWeddings = weddingRepository.count();

        int totalGiftedSft = contributionRepository.sumTotalGiftedSft();
        double totalGiftAmount = contributionRepository.sumTotalGiftedAmount();
        int totalBrickEquivalent = contributionRepository.sumTotalBrickEquivalent();

        // Calculate total registered area across all flats
        List<Flat> allFlats = flatRepository.findAll();
        int totalBuiltUpArea = allFlats.stream().mapToInt(f -> f.getBuiltUpAreaSft() != null ? f.getBuiltUpAreaSft() : 0).sum();
        int totalRemainingSft = Math.max(0, totalBuiltUpArea - totalGiftedSft);

        // Section-wise breakdown
        List<FlatSection> allSections = flatSectionRepository.findAll();
        Map<String, Map<String, Object>> sectionAgg = new LinkedHashMap<>();
        for (FlatSection s : allSections) {
            String name = s.getSectionName();
            sectionAgg.putIfAbsent(name, new LinkedHashMap<>(Map.of("sectionName", name, "totalSft", 0, "giftedSft", 0, "amountGifted", 0.0)));
            Map<String, Object> entry = sectionAgg.get(name);
            int curTot = (int) entry.get("totalSft") + s.getAreaSft();
            int curGift = (int) entry.get("giftedSft") + (s.getGiftedSft() != null ? s.getGiftedSft() : 0);
            double curAmt = (double) entry.get("amountGifted") + ((s.getGiftedSft() != null ? s.getGiftedSft() : 0) * s.getPricePerSft());
            entry.put("totalSft", curTot);
            entry.put("giftedSft", curGift);
            entry.put("amountGifted", curAmt);
        }

        // Flat-wise progress breakdown
        List<Map<String, Object>> flatProgressList = new ArrayList<>();
        for (Flat f : allFlats) {
            int giftedInFlat = flatSectionRepository.sumGiftedSftByFlatId(f.getId());
            int totalInFlat = f.getBuiltUpAreaSft();
            double pct = (totalInFlat > 0) ? ((double) giftedInFlat / totalInFlat) * 100.0 : 0.0;
            flatProgressList.add(Map.of(
                    "flatId", f.getFlatId(),
                    "name", f.getName(),
                    "status", f.getStatus().name(),
                    "totalSft", totalInFlat,
                    "giftedSft", giftedInFlat,
                    "remainingSft", Math.max(0, totalInFlat - giftedInFlat),
                    "progressPercent", Math.round(pct * 10.0) / 10.0
            ));
        }

        // Recent gift transactions (limit 10)
        Pageable recentPage = PageRequest.of(0, 10, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Contribution> recentContribs = contributionRepository.findAll(recentPage);
        List<Map<String, Object>> recentTxns = new ArrayList<>();
        for (Contribution c : recentContribs.getContent()) {
            recentTxns.add(toTransactionMap(c));
        }

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("totalRegisteredFlats", totalFlats);
        resp.put("approvedFlats", approvedFlats);
        resp.put("pendingApprovalFlats", pendingFlats);
        resp.put("assignedFlats", assignedFlats);
        resp.put("draftFlats", draftFlats);
        resp.put("totalWeddings", totalWeddings);

        resp.put("totalBuiltUpAreaSft", totalBuiltUpArea);
        resp.put("totalGiftedSqFt", totalGiftedSft);
        resp.put("totalRemainingSqFt", totalRemainingSft);
        resp.put("totalGiftAmount", totalGiftAmount);
        resp.put("totalBrickEquivalentGifted", totalBrickEquivalent);

        resp.put("sectionWiseBreakdown", new ArrayList<>(sectionAgg.values()));
        resp.put("flatWiseProgress", flatProgressList);
        resp.put("recentTransactions", recentTxns);

        return resp;
    }

    /**
     * Search and Filter Gift Transactions with Pagination
     */
    public Page<Map<String, Object>> searchTransactions(Long weddingId, Long flatId, Long sectionId, String statusStr, String query, Pageable pageable) {
        PaymentStatus paymentStatus = null;
        if (statusStr != null && !statusStr.isBlank() && !"ALL".equalsIgnoreCase(statusStr)) {
            try {
                paymentStatus = PaymentStatus.valueOf(statusStr.trim());
            } catch (Exception ignored) {}
        }

        Page<Contribution> page = contributionRepository.searchContributions(
                weddingId, flatId, sectionId, paymentStatus,
                (query != null && !query.isBlank()) ? query.trim() : null,
                pageable
        );

        return page.map(this::toTransactionMap);
    }

    /**
     * Generate CSV content for Gift Transactions export
     */
    public String exportTransactionsToCsv() {
        List<Contribution> all = contributionRepository.findAll(Sort.by(Sort.Direction.DESC, "createdAt"));
        StringBuilder csv = new StringBuilder();
        csv.append("Transaction ID,Reference Number,Guest Name,Guest Mobile,Guest Email,Wedding ID,Flat ID,Section Name,Gifted Sq Ft,Brick Equivalent,Amount (INR),Payment Status,Date Time\n");

        for (Contribution c : all) {
            csv.append(escapeCsv(String.valueOf(c.getId()))).append(",");
            csv.append(escapeCsv(c.getTxnId())).append(",");
            csv.append(escapeCsv(c.getGuestName())).append(",");
            csv.append(escapeCsv(c.getGuestMobile())).append(",");
            csv.append(escapeCsv(c.getGuestEmail() != null ? c.getGuestEmail() : "")).append(",");
            csv.append(escapeCsv(String.valueOf(c.getWeddingId()))).append(",");
            csv.append(escapeCsv(c.getFlatId() != null ? String.valueOf(c.getFlatId()) : "")).append(",");
            csv.append(escapeCsv(c.getSectionName() != null ? c.getSectionName() : "General")).append(",");
            csv.append(c.getUnitsSft()).append(",");
            csv.append(c.getBrickEquivalent() != null ? c.getBrickEquivalent() : c.getUnitsSft() * 10).append(",");
            csv.append(c.getAmount()).append(",");
            csv.append(c.getPaymentStatus() != null ? c.getPaymentStatus().name() : "SUCCESS").append(",");
            csv.append(escapeCsv(c.getCreatedAt() != null ? c.getCreatedAt().toString() : "")).append("\n");
        }
        return csv.toString();
    }

    private Map<String, Object> toTransactionMap(Contribution c) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", c.getId());
        map.put("txnId", c.getTxnId());
        map.put("guestName", c.getGuestName() != null ? c.getGuestName() : (Boolean.TRUE.equals(c.getIsAnonymous()) ? "Anonymous Well-Wisher" : "Wedding Guest"));
        map.put("guestMobile", c.getGuestMobile() != null ? c.getGuestMobile() : "+91 98480 12345");
        map.put("guestEmail", c.getGuestEmail() != null ? c.getGuestEmail() : "");
        map.put("weddingId", c.getWeddingId());
        map.put("flatId", c.getFlatId());
        map.put("sectionId", c.getSectionId());
        map.put("sectionName", c.getSectionName() != null ? c.getSectionName() : "General Sq. Ft.");
        map.put("giftedSft", c.getUnitsSft());
        map.put("brickEquivalent", c.getBrickEquivalent() != null ? c.getBrickEquivalent() : c.getUnitsSft() * 10);
        map.put("amountPaid", c.getAmount());
        map.put("paymentStatus", c.getPaymentStatus() != null ? c.getPaymentStatus().name() : "SUCCESS");
        map.put("paymentDate", c.getCreatedAt() != null ? c.getCreatedAt().toString() : "");
        map.put("blessingMessage", c.getBlessingMessage() != null ? c.getBlessingMessage() : "");
        return map;
    }

    private String escapeCsv(String val) {
        if (val == null) return "\"\"";
        return "\"" + val.replace("\"", "\"\"") + "\"";
    }
}
