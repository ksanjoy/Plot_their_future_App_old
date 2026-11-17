package com.plottheirfuture.plottheirfuture_backend.service;

import com.plottheirfuture.plottheirfuture_backend.entity.Ceremony;
import com.plottheirfuture.plottheirfuture_backend.exception.ResourceNotFoundException;
import com.plottheirfuture.plottheirfuture_backend.repository.CeremonyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
public class CeremonyService {

    private final CeremonyRepository ceremonyRepository;

    // Concurrent read cache to absorb 100k+ simultaneous itinerary views
    private final Map<Long, List<Ceremony>> weddingCeremonyCache = new ConcurrentHashMap<>(1024);

    public List<Ceremony> getAllCeremonies() {
        return ceremonyRepository.findAll();
    }

    public Ceremony getCeremonyById(Long id) {
        return ceremonyRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Ceremony not found with id: " + id));
    }

    public List<Ceremony> getCeremoniesByWeddingId(Long weddingId) {
        List<Ceremony> cached = weddingCeremonyCache.get(weddingId);
        if (cached != null) return cached;

        List<Ceremony> list = ceremonyRepository.findByWeddingIdOrderByEventDateAscStartTimeAsc(weddingId);
        weddingCeremonyCache.put(weddingId, list);
        return list;
    }

    @Transactional
    public Ceremony createCeremony(Ceremony ceremony) {
        Ceremony saved = ceremonyRepository.save(ceremony);
        if (saved.getWeddingId() != null) {
            weddingCeremonyCache.remove(saved.getWeddingId());
        }
        return saved;
    }

    @Transactional
    public Ceremony updateCeremony(Long id, Ceremony updated) {
        Ceremony existing = getCeremonyById(id);

        if (updated.getWeddingId() != null) existing.setWeddingId(updated.getWeddingId());
        if (updated.getCeremonyType() != null) existing.setCeremonyType(updated.getCeremonyType());
        if (updated.getName() != null) existing.setName(updated.getName());
        if (updated.getEventDate() != null) existing.setEventDate(updated.getEventDate());
        if (updated.getStartTime() != null) existing.setStartTime(updated.getStartTime());
        if (updated.getEndTime() != null) existing.setEndTime(updated.getEndTime());
        if (updated.getVenueName() != null) existing.setVenueName(updated.getVenueName());
        if (updated.getVenueAddress() != null) existing.setVenueAddress(updated.getVenueAddress());
        if (updated.getVenueMapUrl() != null) existing.setVenueMapUrl(updated.getVenueMapUrl());
        if (updated.getCeremonyImageUrl() != null) existing.setCeremonyImageUrl(updated.getCeremonyImageUrl());
        if (updated.getDressCode() != null) existing.setDressCode(updated.getDressCode());
        if (updated.getNotes() != null) existing.setNotes(updated.getNotes());

        Ceremony saved = ceremonyRepository.save(existing);
        if (saved.getWeddingId() != null) {
            weddingCeremonyCache.remove(saved.getWeddingId());
        }
        return saved;
    }

    @Transactional
    public void deleteCeremony(Long id) {
        Ceremony existing = getCeremonyById(id);
        if (existing.getWeddingId() != null) {
            weddingCeremonyCache.remove(existing.getWeddingId());
        }
        ceremonyRepository.deleteById(id);
    }
}
