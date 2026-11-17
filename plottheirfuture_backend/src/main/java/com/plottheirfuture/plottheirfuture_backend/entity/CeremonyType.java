package com.plottheirfuture.plottheirfuture_backend.entity;

import com.fasterxml.jackson.annotation.JsonCreator;

public enum CeremonyType {
    HALDI,
    MEHENDI,
    SANGEET,
    ENGAGEMENT,
    PELLIKUTHURU,
    PELLIKODUKU,
    MUHURTHAM,
    RECEPTION,
    VRATHAM,
    POST_WEDDING_LUNCH,
    CUSTOM;

    @JsonCreator
    public static CeremonyType fromString(String value) {
        if (value == null || value.trim().isEmpty()) {
            return CUSTOM;
        }
        String normalized = value.trim().toUpperCase().replaceAll("[\\s-]+", "_");
        for (CeremonyType type : CeremonyType.values()) {
            if (type.name().equalsIgnoreCase(normalized)) {
                return type;
            }
        }
        return CUSTOM;
    }
}

