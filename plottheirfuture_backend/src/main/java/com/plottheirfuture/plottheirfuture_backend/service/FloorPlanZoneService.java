package com.plottheirfuture.plottheirfuture_backend.service;

import com.plottheirfuture.plottheirfuture_backend.entity.FloorPlanTile;
import com.plottheirfuture.plottheirfuture_backend.entity.FloorPlanZone;
import com.plottheirfuture.plottheirfuture_backend.entity.TileStatus;
import com.plottheirfuture.plottheirfuture_backend.exception.ResourceNotFoundException;
import com.plottheirfuture.plottheirfuture_backend.repository.FloorPlanTileRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.FloorPlanZoneRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
public class FloorPlanZoneService {

    private final FloorPlanZoneRepository floorPlanZoneRepository;
    private final FloorPlanTileRepository floorPlanTileRepository;

    // Concurrent read cache to absorb 100k+ simultaneous room zone views
    private final Map<Long, List<FloorPlanZone>> weddingZoneCache = new ConcurrentHashMap<>(1024);

    public List<FloorPlanZone> getAllZones() {
        return floorPlanZoneRepository.findAll();
    }

    public FloorPlanZone getZoneById(Long id) {
        return floorPlanZoneRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Floor plan zone not found with id: " + id));
    }

    public List<FloorPlanZone> getZonesByWeddingId(Long weddingId) {
        List<FloorPlanZone> cached = weddingZoneCache.get(weddingId);
        if (cached != null) return cached;

        List<FloorPlanZone> list = floorPlanZoneRepository.findByWeddingId(weddingId);
        weddingZoneCache.put(weddingId, list);
        return list;
    }

    public List<Map<String, Object>> getInteractiveZonesByWeddingId(Long weddingId) {
        List<FloorPlanZone> zones = getZonesByWeddingId(weddingId);
        List<Map<String, Object>> result = new ArrayList<>();
        for (FloorPlanZone z : zones) {
            Map<String, Object> zMap = new LinkedHashMap<>();
            zMap.put("id", z.getId());
            zMap.put("weddingId", z.getWeddingId());
            zMap.put("name", z.getRoomName());
            zMap.put("colorHex", z.getColorHex() != null ? z.getColorHex() : "#D4AF37");
            zMap.put("allocatedSft", z.getTotalSft());
            zMap.put("fundedSft", z.getFundedSft());
            zMap.put("ratePerSft", z.getRatePerSft() != null ? z.getRatePerSft() : 4500.0);

            List<FloorPlanTile> tiles = floorPlanTileRepository.findByWeddingIdAndZoneId(weddingId, z.getId());
            List<Map<String, Object>> tileList = new ArrayList<>();
            for (FloorPlanTile t : tiles) {
                Map<String, Object> tMap = new LinkedHashMap<>();
                tMap.put("id", t.getId());
                tMap.put("zoneId", t.getZoneId());
                tMap.put("tileNumber", t.getTileNumber() != null ? t.getTileNumber() : t.getId().intValue());
                String statusStr = "AVAILABLE";
                if (t.getStatus() == TileStatus.HOLD) statusStr = "LOCKED_IN_CART";
                else if (t.getStatus() == TileStatus.FUNDED) statusStr = "GIFTED";
                tMap.put("status", statusStr);
                tMap.put("contributorName", t.getContributorName());
                tMap.put("blessing", t.getBlessing());
                tileList.add(tMap);
            }
            zMap.put("tiles", tileList);
            result.add(zMap);
        }
        return result;
    }

    @Transactional
    public FloorPlanZone createZone(FloorPlanZone zone) {
        FloorPlanZone saved = floorPlanZoneRepository.save(zone);
        if (saved.getWeddingId() != null) {
            weddingZoneCache.remove(saved.getWeddingId());
        }
        return saved;
    }

    @Transactional
    public FloorPlanZone updateZone(Long id, FloorPlanZone updated) {
        FloorPlanZone existing = getZoneById(id);

        if (updated.getRoomName() != null) existing.setRoomName(updated.getRoomName());
        if (updated.getTotalSft() != null) existing.setTotalSft(updated.getTotalSft());
        if (updated.getFundedSft() != null) existing.setFundedSft(updated.getFundedSft());
        if (updated.getColorHex() != null) existing.setColorHex(updated.getColorHex());
        if (updated.getRatePerSft() != null) existing.setRatePerSft(updated.getRatePerSft());
        if (updated.getSvgElementId() != null) existing.setSvgElementId(updated.getSvgElementId());

        FloorPlanZone saved = floorPlanZoneRepository.save(existing);
        if (saved.getWeddingId() != null) {
            weddingZoneCache.remove(saved.getWeddingId());
        }
        return saved;
    }

    @Transactional
    public void deleteZone(Long id) {
        FloorPlanZone existing = getZoneById(id);
        if (existing.getWeddingId() != null) {
            weddingZoneCache.remove(existing.getWeddingId());
        }
        floorPlanZoneRepository.deleteById(id);
    }
}
