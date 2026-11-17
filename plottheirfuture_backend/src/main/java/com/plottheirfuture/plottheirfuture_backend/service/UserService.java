package com.plottheirfuture.plottheirfuture_backend.service;

import com.plottheirfuture.plottheirfuture_backend.entity.User;
import com.plottheirfuture.plottheirfuture_backend.exception.ResourceNotFoundException;
import com.plottheirfuture.plottheirfuture_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    public User getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));
    }

    public User getUserByMobileNumber(String mobileNumber) {
        return userRepository.findByMobileNumber(mobileNumber)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with mobile number: " + mobileNumber));
    }

    private String normalizePhone(String raw) {
        if (raw == null) return null;
        String cleaned = raw.replaceAll("[^0-9+]", "");
        if (!cleaned.startsWith("+")) {
            if (cleaned.length() == 10) {
                cleaned = "+91" + cleaned;
            } else if (cleaned.length() == 12 && cleaned.startsWith("91")) {
                cleaned = "+" + cleaned;
            }
        }
        return cleaned;
    }

    @Transactional
    public User createUser(User user) {
        if (user.getMobileNumber() != null) {
            user.setMobileNumber(normalizePhone(user.getMobileNumber()));
            if (userRepository.existsByMobileNumber(user.getMobileNumber())) {
                throw new IllegalArgumentException("Mobile number already in use: " + user.getMobileNumber());
            }
        }
        if (user.getPassword() != null && !user.getPassword().isBlank()) {
            user.setPassword(passwordEncoder.encode(user.getPassword()));
        }
        return userRepository.save(user);
    }

    @Transactional
    public User updateUser(Long id, User updatedUser) {
        User existing = getUserById(id);

        if (updatedUser.getName() != null) existing.setName(updatedUser.getName());
        if (updatedUser.getPassword() != null && !updatedUser.getPassword().isBlank()) {
            if (!updatedUser.getPassword().startsWith("$2a$") && !updatedUser.getPassword().startsWith("$2b$")) {
                existing.setPassword(passwordEncoder.encode(updatedUser.getPassword()));
            } else {
                existing.setPassword(updatedUser.getPassword());
            }
        }
        if (updatedUser.getMobileNumber() != null && !updatedUser.getMobileNumber().equals(existing.getMobileNumber())) {
            if (userRepository.existsByMobileNumber(updatedUser.getMobileNumber())) {
                throw new IllegalArgumentException("Mobile number already in use: " + updatedUser.getMobileNumber());
            }
            existing.setMobileNumber(updatedUser.getMobileNumber());
        }
        if (updatedUser.getRole() != null) existing.setRole(updatedUser.getRole());
        if (updatedUser.getOccupation() != null) existing.setOccupation(updatedUser.getOccupation());
        if (updatedUser.getOtp() != null) existing.setOtp(updatedUser.getOtp());
        if (updatedUser.getRoleId() != null) existing.setRoleId(updatedUser.getRoleId());
        if (updatedUser.getRegistered() != null) existing.setRegistered(updatedUser.getRegistered());
        if (updatedUser.getImage() != null) existing.setImage(updatedUser.getImage());
        if (updatedUser.getLocationId() != null) existing.setLocationId(updatedUser.getLocationId());

        return userRepository.save(existing);
    }

    @Transactional
    public void deleteUser(Long id) {
        if (!userRepository.existsById(id)) {
            throw new ResourceNotFoundException("User not found with id: " + id);
        }
        userRepository.deleteById(id);
    }
}
