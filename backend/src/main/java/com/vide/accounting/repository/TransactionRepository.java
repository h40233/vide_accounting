package com.vide.accounting.repository;

import com.vide.accounting.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, UUID> {
    List<Transaction> findByFamilyId(UUID familyId);
    List<Transaction> findByUserId(UUID userId);
}
