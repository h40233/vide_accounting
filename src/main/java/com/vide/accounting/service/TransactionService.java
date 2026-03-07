package com.vide.accounting.service;

import com.vide.accounting.dto.TransactionRequest;
import com.vide.accounting.dto.TransactionResponse;
import com.vide.accounting.entity.Family;
import com.vide.accounting.entity.Transaction;
import com.vide.accounting.entity.User;
import com.vide.accounting.exception.AccessDeniedException;
import com.vide.accounting.exception.ResourceNotFoundException;
import com.vide.accounting.repository.TransactionRepository;
import com.vide.accounting.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;

    public TransactionService(TransactionRepository transactionRepository, UserRepository userRepository) {
        this.transactionRepository = transactionRepository;
        this.userRepository = userRepository;
    }

    private User getAuthenticatedUser(UUID authUserId) {
        return userRepository.findById(authUserId)
                .orElseThrow(() -> new AccessDeniedException("User not registered in database: " + authUserId));
    }

    private Family getUserFamily(User user) {
        Family family = user.getFamily();
        if (family == null) {
            throw new AccessDeniedException("User does not belong to any family context");
        }
        return family;
    }

    @Transactional(readOnly = true)
    public List<TransactionResponse> getTransactionsByFamily(UUID authUserId) {
        User user = getAuthenticatedUser(authUserId);
        Family family = getUserFamily(user);

        return transactionRepository.findByFamilyId(family.getId())
                .stream()
                .map(TransactionResponse::new)
                .collect(Collectors.toList());
    }

    @Transactional
    public TransactionResponse createTransaction(UUID authUserId, TransactionRequest request) {
        User user = getAuthenticatedUser(authUserId);
        Family family = getUserFamily(user);

        Transaction tx = new Transaction();
        tx.setUser(user);
        tx.setFamily(family);
        tx.setAmount(request.getAmount());
        tx.setCategory(request.getCategory());
        tx.setType(request.getType());
        tx.setDate(request.getDate());
        tx.setNote(request.getNote());

        Transaction savedTx = transactionRepository.save(tx);
        return new TransactionResponse(savedTx);
    }

    @Transactional
    public TransactionResponse updateTransaction(UUID authUserId, UUID transactionId, TransactionRequest request) {
        User user = getAuthenticatedUser(authUserId);
        Family family = getUserFamily(user);

        Transaction tx = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found: " + transactionId));

        if (!tx.getFamily().getId().equals(family.getId())) {
            throw new AccessDeniedException("You don't have permission to modify this transaction");
        }

        tx.setAmount(request.getAmount());
        tx.setCategory(request.getCategory());
        tx.setType(request.getType());
        tx.setDate(request.getDate());
        tx.setNote(request.getNote());

        Transaction savedTx = transactionRepository.save(tx);
        return new TransactionResponse(savedTx);
    }

    @Transactional
    public void deleteTransaction(UUID authUserId, UUID transactionId) {
        User user = getAuthenticatedUser(authUserId);
        Family family = getUserFamily(user);

        Transaction tx = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found: " + transactionId));

        if (!tx.getFamily().getId().equals(family.getId())) {
            throw new AccessDeniedException("You don't have permission to delete this transaction");
        }

        transactionRepository.delete(tx);
    }
}
