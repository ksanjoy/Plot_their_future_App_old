package com.plottheirfuture.plottheirfuture_backend.service;

import com.plottheirfuture.plottheirfuture_backend.entity.WebApp;
import com.plottheirfuture.plottheirfuture_backend.entity.WebAppType;
import com.plottheirfuture.plottheirfuture_backend.exception.ResourceNotFoundException;
import com.plottheirfuture.plottheirfuture_backend.repository.WebAppRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

@Service
@RequiredArgsConstructor
public class WebAppService {

    private final WebAppRepository webAppRepository;

    // In-memory cache for active branding/portal configurations
    private volatile List<WebApp> cachedActiveWebApps = null;

    public List<WebApp> getAllWebApps() {
        return webAppRepository.findAll();
    }

    public WebApp getWebAppById(Long id) {
        return webAppRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("WebApp not found with id: " + id));
    }

    public List<WebApp> getActiveWebApps() {
        if (cachedActiveWebApps != null) return cachedActiveWebApps;
        List<WebApp> active = webAppRepository.findByActiveTrue();
        cachedActiveWebApps = new CopyOnWriteArrayList<>(active);
        return cachedActiveWebApps;
    }

    public List<WebApp> getWebAppsByType(WebAppType type) {
        return webAppRepository.findByType(type);
    }

    @Transactional
    public WebApp createWebApp(WebApp webApp) {
        WebApp saved = webAppRepository.save(webApp);
        cachedActiveWebApps = null;
        return saved;
    }

    @Transactional
    public WebApp updateWebApp(Long id, WebApp updated) {
        WebApp existing = getWebAppById(id);

        if (updated.getName() != null) existing.setName(updated.getName());
        if (updated.getType() != null) existing.setType(updated.getType());
        if (updated.getActive() != null) existing.setActive(updated.getActive());
        if (updated.getPrimaryColour() != null) existing.setPrimaryColour(updated.getPrimaryColour());
        if (updated.getSecondaryColour() != null) existing.setSecondaryColour(updated.getSecondaryColour());
        if (updated.getThemeColour() != null) existing.setThemeColour(updated.getThemeColour());
        if (updated.getHeroImages() != null) existing.setHeroImages(updated.getHeroImages());

        WebApp saved = webAppRepository.save(existing);
        cachedActiveWebApps = null;
        return saved;
    }

    @Transactional
    public void deleteWebApp(Long id) {
        if (!webAppRepository.existsById(id)) {
            throw new ResourceNotFoundException("WebApp not found with id: " + id);
        }
        webAppRepository.deleteById(id);
        cachedActiveWebApps = null;
    }

    @Transactional
    public WebApp addHeroImage(Long id, String imageUrl) {
        WebApp webApp = getWebAppById(id);
        webApp.getHeroImages().add(imageUrl);
        WebApp saved = webAppRepository.save(webApp);
        cachedActiveWebApps = null;
        return saved;
    }

    @Transactional
    public WebApp removeHeroImage(Long id, String imageUrl) {
        WebApp webApp = getWebAppById(id);
        webApp.getHeroImages().remove(imageUrl);
        WebApp saved = webAppRepository.save(webApp);
        cachedActiveWebApps = null;
        return saved;
    }
}
